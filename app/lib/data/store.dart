import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/campus.dart';
import '../core/matching.dart';
import '../core/models.dart';
import '../core/text_tools.dart';
import 'storage.dart';

class StoreError implements Exception {
  StoreError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// A report being written, before it is saved.
class ReportDraft {
  ReportDraft({
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    this.colour,
    required this.zone,
    required this.eventTime,
    this.desk = false,
  });

  final ReportType type;
  final String title;
  final String description;
  final String category;
  final String? colour;
  final String zone;
  final DateTime eventTime;
  final bool desk;
}

/// A question the finder asks and the hidden answer to compare against.
class QA {
  const QA(this.question, this.answer);
  final String question;
  final String answer;
}

const dailyReportLimit = 5;
const pendingClaimLimit = 3;

/// All app data and actions. Screens read lists from here and call methods.
/// Matching runs on this phone for now (an interim step; the brief puts it on
/// the backend).
class AppStore extends ChangeNotifier {
  AppStore(this.auth, this.storage, {required this.localMode});

  final AuthService auth;
  final Storage storage;

  /// True when Firebase is not configured and data stays on this phone.
  final bool localMode;

  AppUser? user;
  bool guest = false;
  bool ready = false;

  /// Last problem reading from the database (for example a rules error).
  String? syncError;
  Future<void>? _opening;

  List<Report> reports = [];
  List<MatchRec> matches = [];
  List<Claim> claims = [];
  List<Notice> notices = [];
  List<FlagRec> flags = [];

  final _subs = <StreamSubscription<dynamic>>[];
  StreamSubscription<AuthUser?>? _authSub;
  final _parts = <String, List<Row>>{};
  final _rng = Random.secure();

  bool get signedIn => user != null;
  bool get hasSession => user != null || guest;
  bool get isAdmin => user?.isAdmin ?? false;
  String get uid => user?.uid ?? '';

  // ---- start up and sessions ----

  Future<void> init() async {
    final existing = auth.current;
    if (existing != null) {
      await _openSession(existing);
    }
    ready = true;
    notifyListeners();
    _authSub = auth.changes.listen((u) async {
      if (u == null) {
        _closeSession();
      } else if (user?.uid != u.uid) {
        // signUp/signIn open the session themselves; wait for that instead of
        // opening it twice at the same time.
        await _opening;
        if (user?.uid != u.uid) await _openSession(u);
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _cancelSubs();
    super.dispose();
  }

  Future<void> _openSession(AuthUser u, {String? ageBand}) async {
    if (u.anonymous) {
      guest = true;
      user = null;
      _attachPublic();
      return;
    }
    guest = false;
    var row = await storage.get('users', u.uid);
    if (row == null) {
      final created = AppUser(
        uid: u.uid,
        email: u.email,
        // In local mode the single user is also the campus admin, so the whole
        // claim flow can be tried on one phone.
        role: localMode ? 'admin' : 'user',
        ageBand: ageBand ?? '13-17',
        createdAt: DateTime.now(),
      );
      await storage.put('users', u.uid, created.toMap());
      row = created.toMap();
    }
    user = AppUser.fromMap(row);
    _attach();
    unawaited(_maintenance());
  }

  void _closeSession() {
    _cancelSubs();
    user = null;
    guest = false;
    reports = [];
    matches = [];
    claims = [];
    notices = [];
    flags = [];
    syncError = null;
  }

  void _cancelSubs() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _parts.clear();
  }

  void _listen(String key, Stream<List<Row>> stream, void Function() apply) {
    _subs.add(stream.listen((rows) {
      _parts[key] = rows;
      if (key == 'reports') syncError = null;
      try {
        apply();
      } catch (e) {
        syncError = 'Could not read $key: $e';
      }
      notifyListeners();
    }, onError: (Object e) {
      syncError = 'Could not load $key: $e';
      if (kDebugMode) debugPrint('watch $key failed: $e');
      notifyListeners();
    }));
  }

  List<Row> _merge(List<String> keys) {
    final byId = <String, Row>{};
    for (final k in keys) {
      for (final r in _parts[k] ?? const <Row>[]) {
        byId[r['id'] as String] = r;
      }
    }
    return byId.values.toList();
  }

  void _attachPublic() {
    _cancelSubs();
    _listen('reports', storage.watch('reports'), () {
      reports = _parts['reports']!.map(Report.fromMap).toList();
    });
  }

  void _attach() {
    _cancelSubs();
    final me = user!.uid;
    _listen('reports', storage.watch('reports'), () {
      reports = _parts['reports']!.map(Report.fromMap).toList();
    });
    _listen('m1', storage.watch('matches', where: 'lostUserId', equals: me),
        () => matches = _merge(['m1', 'm2']).map(MatchRec.fromMap).toList());
    _listen('m2', storage.watch('matches', where: 'foundUserId', equals: me),
        () => matches = _merge(['m1', 'm2']).map(MatchRec.fromMap).toList());
    if (user!.isAdmin) {
      _listen('c1', storage.watch('claims'),
          () => claims = _merge(['c1']).map(Claim.fromMap).toList());
      _listen('flags', storage.watch('flags'),
          () => flags = _parts['flags']!.map(FlagRec.fromMap).toList());
    } else {
      _listen('c1', storage.watch('claims', where: 'claimantId', equals: me),
          () => claims = _merge(['c1', 'c2']).map(Claim.fromMap).toList());
      _listen('c2', storage.watch('claims', where: 'finderId', equals: me),
          () => claims = _merge(['c1', 'c2']).map(Claim.fromMap).toList());
    }
    _listen('notices', storage.watch('notifications', where: 'userId', equals: me),
        () => notices = _parts['notices']!.map(Notice.fromMap).toList());
  }

  // ---- accounts ----

  Future<void> signUp(String email, String password, String? ageBand) async {
    final u = await auth.signUp(email, password);
    await (_opening = _openSession(u, ageBand: ageBand));
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    final u = await auth.signIn(email, password);
    await (_opening = _openSession(u));
    notifyListeners();
  }

  Future<void> enterGuest() async {
    try {
      final u = await auth.signInGuest();
      await _openSession(u);
    } catch (_) {
      // Guest browsing still works from local state if anonymous sign-in is off.
      guest = true;
      _attachPublic();
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    await auth.signOut();
    _closeSession();
    notifyListeners();
  }

  Future<void> saveProfile(AppUser updated) async {
    user = updated;
    await storage.update('users', updated.uid, {
      'gender': updated.gender,
      'handoverPref': updated.handoverPref,
      'shareContactOptIn': updated.shareContactOptIn,
      'pushOn': updated.pushOn,
      'blocked': updated.blocked,
      'muted': updated.muted,
    });
    notifyListeners();
  }

  /// FR-30: delete the account and its data.
  Future<void> deleteAccount() async {
    final me = user;
    if (me == null) return;
    for (final r in reports.where((r) => r.userId == me.uid)) {
      await storage.remove('reportPrivate', r.id);
      await storage.remove('reports', r.id);
    }
    for (final m in await storage.query('matches', where: 'lostUserId', equals: me.uid)) {
      await storage.remove('matches', m['id'] as String);
    }
    for (final m in await storage.query('matches', where: 'foundUserId', equals: me.uid)) {
      await storage.remove('matches', m['id'] as String);
    }
    for (final c in await storage.query('claims', where: 'claimantId', equals: me.uid)) {
      await storage.remove('claims', c['id'] as String);
    }
    for (final n in await storage.query('notifications', where: 'userId', equals: me.uid)) {
      await storage.remove('notifications', n['id'] as String);
    }
    await storage.remove('users', me.uid);
    await auth.deleteAccount();
    _closeSession();
    notifyListeners();
  }

  // ---- reading ----

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_rng.nextInt(1 << 20).toRadixString(36)}';

  bool _blockedBy(String userId) => user?.blocked.contains(userId) ?? false;

  /// Open reports of this campus, newest first, without blocked users.
  List<Report> get feed => reports
      .where((r) =>
          r.status == statusOpen &&
          r.campusId == kCampusId &&
          !_blockedBy(r.userId))
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Report> get myReports => reports.where((r) => r.userId == uid).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Report? reportById(String id) {
    for (final r in reports) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Matches for one of my reports, best first, without dismissed ones.
  List<MatchRec> matchesFor(Report r) {
    final list = matches
        .where((m) =>
            !m.dismissed &&
            (r.isFound ? m.foundReportId == r.id : m.lostReportId == r.id))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return list.take(maxMatches).toList();
  }

  /// The report on the other side of a match.
  Report? otherSide(MatchRec m, Report mine) =>
      reportById(mine.isFound ? m.lostReportId : m.foundReportId);

  /// New suggestions across my lost reports, best first.
  List<(Report, MatchRec)> get topMatches {
    final out = <(Report, MatchRec)>[];
    for (final r in myReports.where((r) => r.isOpen)) {
      for (final m in matchesFor(r)) {
        out.add((r, m));
      }
    }
    out.sort((a, b) => b.$2.score.compareTo(a.$2.score));
    return out;
  }

  String statusLabel(Report r) {
    if (r.status == statusOpen && matchesFor(r).isNotEmpty) return 'Matched';
    switch (r.status) {
      case statusOpen:
        return 'Open';
      case statusClaimed:
        return 'Claim approved';
      case statusReturned:
        return 'Returned';
      case statusClosed:
        return 'Closed';
      case statusArchived:
        return 'Archived';
      default:
        return r.status;
    }
  }

  Claim? myClaimFor(String foundReportId) {
    for (final c in claims) {
      if (c.foundReportId == foundReportId && c.claimantId == uid) return c;
    }
    return null;
  }

  List<Claim> get myClaims =>
      claims.where((c) => c.claimantId == uid).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Claims on my found reports, plus all claims for an admin.
  List<Claim> claimsToReview() {
    final list = claims
        .where((c) => c.finderId == uid || (isAdmin && c.claimantId != uid))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Notice> get visibleNotices {
    final muted = user?.muted ?? const <String>[];
    final list = notices
        .where((n) => n.reportId == null || !muted.contains(n.reportId))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  int get unreadCount => visibleNotices.where((n) => !n.read).length;

  /// Keyword search over the same normalised text used for matching (FR-14).
  List<Report> search({
    String keyword = '',
    ReportType? type,
    String? category,
    String? zone,
    int? days,
  }) {
    final q = tokens(keyword);
    final cutoff =
        days == null ? null : DateTime.now().subtract(Duration(days: days));
    return feed.where((r) {
      if (type != null && r.type != type) return false;
      if (category != null && r.category != category) return false;
      if (zone != null && r.zone != zone) return false;
      if (cutoff != null && r.eventTime.isBefore(cutoff)) return false;
      if (q.isEmpty) return true;
      final t = tokens('${r.title} ${r.description} ${r.colour ?? ''} ${r.category}');
      return q.any(t.contains);
    }).toList();
  }

  /// Private details (photo and hidden answers). Null if not allowed.
  Future<Row?> privateFor(String reportId) async {
    try {
      return await storage.get('reportPrivate', reportId);
    } catch (_) {
      return null;
    }
  }

  // ---- reports ----

  void _needUser() {
    if (user == null) throw StoreError('Sign in to do this.');
    if (user!.status == 'suspended') {
      throw StoreError('Your account is suspended. Contact the campus desk.');
    }
  }

  Future<Report> createReport(
    ReportDraft d, {
    String? photoBase64,
    List<QA> details = const [],
  }) async {
    _needUser();
    final me = user!;
    final dayAgo = DateTime.now().subtract(const Duration(hours: 24));
    final today = reports
        .where((r) => r.userId == me.uid && r.createdAt.isAfter(dayAgo))
        .length;
    if (today >= dailyReportLimit && !me.isAdmin) {
      throw StoreError('You can post $dailyReportLimit reports a day. Try again tomorrow.');
    }
    final raw = '${d.title} ${d.description} ${details.map((e) => '${e.question} ${e.answer}').join(' ')}';
    if (containsBlockedWord(raw)) {
      throw StoreError('Please remove objectionable words before posting.');
    }
    if (d.type == ReportType.found && details.isEmpty) {
      throw StoreError('Add at least one private verification question.');
    }
    final now = DateTime.now();
    final id = _newId();
    final report = Report(
      id: id,
      userId: me.uid,
      type: d.type,
      title: maskPersonalData(d.title.trim()).text,
      description: maskPersonalData(d.description.trim()).text,
      category: d.category,
      colour: d.colour,
      zone: d.zone,
      eventTime: d.eventTime,
      createdAt: now,
      lastActivityAt: now,
      ownerMinor: me.isMinor,
      desk: d.desk,
      hasPhoto: photoBase64 != null,
      questions: [for (final e in details) maskPersonalData(e.question).text],
    );
    await storage.put('reports', id, report.toMap());
    await storage.put('reportPrivate', id, {
      'ownerId': me.uid,
      'photo': photoBase64,
      'answers': [for (final e in details) maskPersonalData(e.answer).text],
    });
    reports = [...reports, report];
    notifyListeners();
    await _runMatching(report);
    return report;
  }

  /// Scores the new report against open opposite-type reports (FR-09, FR-10).
  Future<void> _runMatching(Report fresh) async {
    final candidates = reports.where((r) =>
        r.id != fresh.id &&
        r.type != fresh.type &&
        r.status == statusOpen &&
        r.campusId == fresh.campusId &&
        r.userId != fresh.userId);
    final found = <(Report, Score)>[];
    for (final c in candidates) {
      final lost = fresh.isFound ? c : fresh;
      final fnd = fresh.isFound ? fresh : c;
      if (!inWindow(lost, fnd)) continue;
      final s = scorePair(lost, fnd);
      if (s.total >= matchThreshold) found.add((c, s));
    }
    found.sort((a, b) => b.$2.total.compareTo(a.$2.total));
    for (final (other, s) in found.take(maxMatches)) {
      final lost = fresh.isFound ? other : fresh;
      final fnd = fresh.isFound ? fresh : other;
      final id = '${lost.id}_${fnd.id}';
      if (matches.any((m) => m.id == id)) continue;
      final rec = MatchRec(
        id: id,
        lostReportId: lost.id,
        foundReportId: fnd.id,
        lostUserId: lost.userId,
        foundUserId: fnd.userId,
        score: s.total,
        text: s.text,
        category: s.category,
        place: s.place,
        time: s.time,
        reason: s.reason,
        createdAt: DateTime.now(),
      );
      await storage.put('matches', id, rec.toMap());
      matches = [...matches, rec];
      await _notify(
        other.userId,
        kind: 'match',
        title: 'Possible match',
        body: '${fresh.title} may match your ${other.isFound ? 'found' : 'lost'} item "${other.title}". Score ${s.total.toStringAsFixed(2)}.',
        refId: id,
        reportId: other.id,
      );
    }
    notifyListeners();
  }

  Future<void> _notify(
    String toUser, {
    required String kind,
    required String title,
    required String body,
    String? refId,
    String? reportId,
  }) async {
    if (toUser.isEmpty || toUser == uid) return;
    final id = _newId();
    try {
      await storage.put(
        'notifications',
        id,
        Notice(
          id: id,
          userId: toUser,
          kind: kind,
          title: title,
          body: body,
          refId: refId,
          reportId: reportId,
          createdAt: DateTime.now(),
        ).toMap(),
      );
    } catch (_) {
      // A missed notification must never block the main action.
    }
  }

  Future<void> markRead(Notice n) async {
    if (n.read) return;
    await storage.update('notifications', n.id, {'read': true});
    notices = [
      for (final x in notices)
        if (x.id == n.id)
          Notice(
            id: x.id,
            userId: x.userId,
            kind: x.kind,
            title: x.title,
            body: x.body,
            refId: x.refId,
            reportId: x.reportId,
            read: true,
            createdAt: x.createdAt,
          )
        else
          x,
    ];
    notifyListeners();
  }

  Future<void> dismissMatch(MatchRec m) async {
    await storage.update('matches', m.id, {'status': 'dismissed'});
    matches = [for (final x in matches) x.id == m.id ? x.withStatus('dismissed') : x];
    notifyListeners();
  }

  Future<void> _setStatus(Report r, String status, {bool touch = false}) async {
    final patch = <String, dynamic>{'status': status};
    if (touch) patch['lastActivityAt'] = DateTime.now().millisecondsSinceEpoch;
    await storage.update('reports', r.id, patch);
    reports = [
      for (final x in reports)
        x.id == r.id
            ? x.copyWith(
                status: status,
                lastActivityAt: touch ? DateTime.now() : null,
              )
            : x,
    ];
    notifyListeners();
  }

  Future<void> closeReport(Report r) => _setStatus(r, statusClosed);

  Future<void> renewReport(Report r) =>
      _setStatus(r, statusOpen, touch: true);

  Future<void> deleteReport(Report r) async {
    await storage.remove('reportPrivate', r.id);
    await storage.remove('reports', r.id);
    reports = reports.where((x) => x.id != r.id).toList();
    notifyListeners();
  }

  Future<void> toggleMute(Report r) async {
    final me = user;
    if (me == null) return;
    final muted = [...me.muted];
    if (!muted.remove(r.id)) muted.add(r.id);
    await saveProfile(me.copyWith(muted: muted));
  }

  /// FR-26: archive reports with no activity for 30 days.
  Future<void> _maintenance() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    for (final r in reports.where((r) =>
        r.userId == uid && r.status == statusOpen && r.lastActivityAt.isBefore(cutoff))) {
      await _setStatus(r, statusArchived);
    }
  }

  // ---- claims ----

  Future<Claim> submitClaim(Report found, List<String> answers, String note) async {
    _needUser();
    final me = user!;
    if (found.userId == me.uid) throw StoreError('You cannot claim your own report.');
    if (myClaimFor(found.id) != null) {
      throw StoreError('You already claimed this item.');
    }
    final pending = claims.where((c) => c.claimantId == me.uid && c.pending).length;
    if (pending >= pendingClaimLimit) {
      throw StoreError('You can have $pendingClaimLimit pending claims at a time.');
    }
    if (answers.every((a) => a.trim().isEmpty)) {
      throw StoreError('Answer at least one question.');
    }
    if (containsBlockedWord('${answers.join(' ')} $note')) {
      throw StoreError('Please remove objectionable words.');
    }
    final claim = Claim(
      id: '${found.id}_${me.uid}',
      foundReportId: found.id,
      foundTitle: found.title,
      claimantId: me.uid,
      finderId: found.userId,
      answers: [for (final a in answers) maskPersonalData(a.trim()).text],
      note: maskPersonalData(note.trim()).text,
      // FR-... age rule: claims made or received by 13-17 are reviewed by an admin.
      requiresAdmin: me.isMinor || found.ownerMinor,
      createdAt: DateTime.now(),
    );
    await storage.put('claims', claim.id, claim.toMap());
    claims = [...claims, claim];
    await _notify(
      found.userId,
      kind: 'claim',
      title: 'New claim',
      body: 'Someone claimed "${found.title}". Review their answers.',
      refId: claim.id,
      reportId: found.id,
    );
    notifyListeners();
    return claim;
  }

  bool canReview(Claim c) {
    if (c.requiresAdmin) return isAdmin;
    return isAdmin || c.finderId == uid;
  }

  Future<void> decideClaim(Claim c, {required bool approve}) async {
    if (!canReview(c)) {
      throw StoreError('A campus admin must review this claim.');
    }
    final now = DateTime.now();
    final code = approve ? (100000 + _rng.nextInt(900000)).toString() : null;
    await storage.update('claims', c.id, {
      'status': approve ? 'approved' : 'rejected',
      'reviewerId': uid,
      'decidedAt': now.millisecondsSinceEpoch,
      'handoverCode': code,
    });
    if (approve) {
      await storage.update('reports', c.foundReportId, {'status': statusClaimed});
    }
    await _audit(approve ? 'claim_approved' : 'claim_rejected', c.id);
    await _notify(
      c.claimantId,
      kind: 'claim',
      title: approve ? 'Claim approved' : 'Claim rejected',
      body: approve
          ? 'Your claim for "${c.foundTitle}" was approved. Your handover code is ready.'
          : 'Your claim for "${c.foundTitle}" was not approved.',
      refId: c.id,
      reportId: c.foundReportId,
    );
    claims = [
      for (final x in claims)
        x.id == c.id
            ? Claim(
                id: x.id,
                foundReportId: x.foundReportId,
                foundTitle: x.foundTitle,
                claimantId: x.claimantId,
                finderId: x.finderId,
                answers: x.answers,
                note: x.note,
                status: approve ? 'approved' : 'rejected',
                requiresAdmin: x.requiresAdmin,
                handoverCode: code,
                reviewerId: uid,
                createdAt: x.createdAt,
                decidedAt: now,
              )
            : x,
    ];
    if (approve) {
      reports = [
        for (final r in reports)
          r.id == c.foundReportId ? r.copyWith(status: statusClaimed) : r,
      ];
    }
    notifyListeners();
  }

  /// FR-25: the finder or desk types the claimant's code to finish the return.
  Future<bool> completeClaim(Claim c, String code) async {
    if (!canReview(c)) return false;
    if (c.handoverCode == null || c.handoverCode != code.trim()) return false;
    await storage.update('claims', c.id, {'status': 'completed'});
    await storage.update('reports', c.foundReportId, {'status': statusReturned});
    await _audit('handover_completed', c.id);
    await _notify(
      c.claimantId,
      kind: 'handover',
      title: 'Item returned',
      body: '"${c.foundTitle}" was handed over. Thank you for using Foundit.',
      refId: c.id,
      reportId: c.foundReportId,
    );
    claims = [
      for (final x in claims)
        x.id == c.id
            ? Claim(
                id: x.id,
                foundReportId: x.foundReportId,
                foundTitle: x.foundTitle,
                claimantId: x.claimantId,
                finderId: x.finderId,
                answers: x.answers,
                note: x.note,
                status: 'completed',
                requiresAdmin: x.requiresAdmin,
                handoverCode: x.handoverCode,
                reviewerId: x.reviewerId,
                createdAt: x.createdAt,
                decidedAt: x.decidedAt,
              )
            : x,
    ];
    reports = [
      for (final r in reports)
        r.id == c.foundReportId ? r.copyWith(status: statusReturned) : r,
    ];
    notifyListeners();
    return true;
  }

  Future<void> withdrawClaim(Claim c) async {
    await storage.update('claims', c.id, {'status': 'withdrawn'});
    claims = claims.where((x) => x.id != c.id).toList();
    notifyListeners();
  }

  // ---- moderation ----

  Future<void> flagReport(Report r, String reason) async {
    _needUser();
    final id = _newId();
    await storage.put(
      'flags',
      id,
      FlagRec(
        id: id,
        targetType: 'report',
        targetId: r.id,
        targetUserId: r.userId,
        reporterId: uid,
        reason: reason,
        summary: r.title,
        createdAt: DateTime.now(),
      ).toMap(),
    );
  }

  Future<void> flagOther(String targetType, String summary, String reason) async {
    _needUser();
    final id = _newId();
    await storage.put(
      'flags',
      id,
      FlagRec(
        id: id,
        targetType: targetType,
        targetId: '',
        targetUserId: '',
        reporterId: uid,
        reason: reason,
        summary: summary,
        createdAt: DateTime.now(),
      ).toMap(),
    );
  }

  Future<void> blockUser(String userId) async {
    final me = user;
    if (me == null || userId.isEmpty || userId == me.uid) return;
    if (me.blocked.contains(userId)) return;
    await saveProfile(me.copyWith(blocked: [...me.blocked, userId]));
  }

  Future<void> _audit(String action, String targetId) async {
    try {
      final id = _newId();
      await storage.put('auditLogs', id, {
        'actorId': uid,
        'action': action,
        'targetId': targetId,
        'at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {
      // Logging must not block the action itself.
    }
  }

  // ---- admin ----

  Future<void> resolveFlag(FlagRec f, {required String outcome}) async {
    if (!isAdmin) return;
    if (outcome == 'hidden') {
      final r = reportById(f.targetId);
      if (r != null) await _setStatus(r, statusHidden);
    }
    if (outcome == 'suspended' && f.targetUserId.isNotEmpty) {
      await storage.update('users', f.targetUserId, {'status': 'suspended'});
    }
    await storage.update('flags', f.id, {'status': outcome});
    await _audit('flag_$outcome', f.id);
    flags = [
      for (final x in flags)
        x.id == f.id
            ? FlagRec(
                id: x.id,
                targetType: x.targetType,
                targetId: x.targetId,
                targetUserId: x.targetUserId,
                reporterId: x.reporterId,
                reason: x.reason,
                summary: x.summary,
                status: outcome,
                createdAt: x.createdAt,
              )
            : x,
    ];
    notifyListeners();
  }

  List<Report> get deskReports =>
      reports.where((r) => r.desk && r.status == statusOpen).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Counts for the admin stats tab.
  Map<String, int> get stats {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return {
      'Open reports': reports.where((r) => r.status == statusOpen).length,
      'Claims pending': claims.where((c) => c.pending).length,
      'Returned this week': reports
          .where((r) => r.status == statusReturned && r.lastActivityAt.isAfter(weekAgo))
          .length,
      'Flags open': flags.where((f) => f.status == 'open').length,
    };
  }

  /// Short reminder for a found report held for 3 days (not at the desk).
  bool needsDeskReminder(Report r) =>
      r.isFound &&
      !r.desk &&
      r.status == statusOpen &&
      DateTime.now().difference(r.createdAt).inDays >= 3;

  bool needsRenewal(Report r) =>
      r.status == statusOpen &&
      DateTime.now().difference(r.lastActivityAt).inDays >= 25;
}
