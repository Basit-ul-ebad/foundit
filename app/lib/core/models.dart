// Plain data classes. Every class converts to and from a Map so the same code
// works with local storage and Firestore. Times are stored as epoch millis.

DateTime _dt(Object? v) =>
    DateTime.fromMillisecondsSinceEpoch(((v as num?) ?? 0).toInt());

int _ms(DateTime d) => d.millisecondsSinceEpoch;

List<String> _strings(Object? v) =>
    (v as List?)?.map((e) => e.toString()).toList() ?? <String>[];

enum ReportType { lost, found }

// Report status values stored in the database.
const statusOpen = 'open';
const statusClaimed = 'claimed';
const statusReturned = 'returned';
const statusClosed = 'closed';
const statusArchived = 'archived';
const statusHidden = 'hidden';

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    this.role = 'user',
    this.ageBand = '13-17',
    this.gender = 'Prefer not to say',
    this.handoverPref = 'At the desk',
    this.shareContactOptIn = false,
    this.pushOn = true,
    this.blocked = const [],
    this.muted = const [],
    this.status = 'active',
    this.campusId = 'comsats-isb',
    required this.createdAt,
  });

  final String uid;
  final String email;
  final String role;
  final String ageBand;
  final String gender;
  final String handoverPref;
  final bool shareContactOptIn;
  final bool pushOn;
  final List<String> blocked;
  final List<String> muted;
  final String status;
  final String campusId;
  final DateTime createdAt;

  bool get isAdmin => role == 'admin';
  bool get isMinor => ageBand == '13-17';

  String get displayName {
    if (email.isEmpty) return 'Guest';
    final name = email.split('@').first;
    return name.isEmpty ? 'Student' : name;
  }

  AppUser copyWith({
    String? gender,
    String? handoverPref,
    bool? shareContactOptIn,
    bool? pushOn,
    List<String>? blocked,
    List<String>? muted,
    String? ageBand,
  }) =>
      AppUser(
        uid: uid,
        email: email,
        role: role,
        ageBand: ageBand ?? this.ageBand,
        gender: gender ?? this.gender,
        handoverPref: handoverPref ?? this.handoverPref,
        shareContactOptIn: shareContactOptIn ?? this.shareContactOptIn,
        pushOn: pushOn ?? this.pushOn,
        blocked: blocked ?? this.blocked,
        muted: muted ?? this.muted,
        status: status,
        campusId: campusId,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': uid,
        'email': email,
        'role': role,
        'ageBand': ageBand,
        'gender': gender,
        'handoverPref': handoverPref,
        'shareContactOptIn': shareContactOptIn,
        'pushOn': pushOn,
        'blocked': blocked,
        'muted': muted,
        'status': status,
        'campusId': campusId,
        'createdAt': _ms(createdAt),
      };

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        uid: m['id'] as String,
        email: (m['email'] as String?) ?? '',
        role: (m['role'] as String?) ?? 'user',
        ageBand: (m['ageBand'] as String?) ?? '13-17',
        gender: (m['gender'] as String?) ?? 'Prefer not to say',
        handoverPref: (m['handoverPref'] as String?) ?? 'At the desk',
        shareContactOptIn: (m['shareContactOptIn'] as bool?) ?? false,
        pushOn: (m['pushOn'] as bool?) ?? true,
        blocked: _strings(m['blocked']),
        muted: _strings(m['muted']),
        status: (m['status'] as String?) ?? 'active',
        campusId: (m['campusId'] as String?) ?? 'comsats-isb',
        createdAt: _dt(m['createdAt']),
      );
}

class Report {
  const Report({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    this.colour,
    required this.zone,
    required this.eventTime,
    this.status = statusOpen,
    required this.createdAt,
    required this.lastActivityAt,
    this.ownerMinor = false,
    this.desk = false,
    this.hasPhoto = false,
    this.questions = const [],
    this.campusId = 'comsats-isb',
  });

  final String id;
  final String userId;
  final ReportType type;
  final String title;
  final String description;
  final String category;
  final String? colour;
  final String zone;
  final DateTime eventTime;
  final String status;
  final DateTime createdAt;
  final DateTime lastActivityAt;
  final bool ownerMinor;
  final bool desk;
  final bool hasPhoto;

  /// Verification questions for found items. The answers are private.
  final List<String> questions;
  final String campusId;

  bool get isFound => type == ReportType.found;
  bool get isOpen => status == statusOpen;

  Report copyWith({String? status, DateTime? lastActivityAt}) => Report(
        id: id,
        userId: userId,
        type: type,
        title: title,
        description: description,
        category: category,
        colour: colour,
        zone: zone,
        eventTime: eventTime,
        status: status ?? this.status,
        createdAt: createdAt,
        lastActivityAt: lastActivityAt ?? this.lastActivityAt,
        ownerMinor: ownerMinor,
        desk: desk,
        hasPhoto: hasPhoto,
        questions: questions,
        campusId: campusId,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'type': type.name,
        'title': title,
        'description': description,
        'category': category,
        'colour': colour,
        'zone': zone,
        'eventTime': _ms(eventTime),
        'status': status,
        'createdAt': _ms(createdAt),
        'lastActivityAt': _ms(lastActivityAt),
        'ownerMinor': ownerMinor,
        'desk': desk,
        'hasPhoto': hasPhoto,
        'questions': questions,
        'campusId': campusId,
      };

  factory Report.fromMap(Map<String, dynamic> m) => Report(
        id: m['id'] as String,
        userId: (m['userId'] as String?) ?? '',
        type: m['type'] == 'found' ? ReportType.found : ReportType.lost,
        title: (m['title'] as String?) ?? '',
        description: (m['description'] as String?) ?? '',
        category: (m['category'] as String?) ?? 'Other',
        colour: m['colour'] as String?,
        zone: (m['zone'] as String?) ?? campusZoneFallback,
        eventTime: _dt(m['eventTime']),
        status: (m['status'] as String?) ?? statusOpen,
        createdAt: _dt(m['createdAt']),
        lastActivityAt: _dt(m['lastActivityAt']),
        ownerMinor: (m['ownerMinor'] as bool?) ?? false,
        desk: (m['desk'] as bool?) ?? false,
        hasPhoto: (m['hasPhoto'] as bool?) ?? false,
        questions: _strings(m['questions']),
        campusId: (m['campusId'] as String?) ?? 'comsats-isb',
      );
}

const campusZoneFallback = 'Library';

class MatchRec {
  const MatchRec({
    required this.id,
    required this.lostReportId,
    required this.foundReportId,
    required this.lostUserId,
    required this.foundUserId,
    required this.score,
    required this.text,
    required this.category,
    required this.place,
    required this.time,
    required this.reason,
    this.status = 'suggested',
    required this.createdAt,
  });

  final String id;
  final String lostReportId;
  final String foundReportId;
  final String lostUserId;
  final String foundUserId;
  final double score;
  final double text;
  final double category;
  final double place;
  final double time;
  final String reason;
  final String status;
  final DateTime createdAt;

  bool get dismissed => status == 'dismissed';

  MatchRec withStatus(String s) => MatchRec(
        id: id,
        lostReportId: lostReportId,
        foundReportId: foundReportId,
        lostUserId: lostUserId,
        foundUserId: foundUserId,
        score: score,
        text: text,
        category: category,
        place: place,
        time: time,
        reason: reason,
        status: s,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'lostReportId': lostReportId,
        'foundReportId': foundReportId,
        'lostUserId': lostUserId,
        'foundUserId': foundUserId,
        'score': score,
        'text': text,
        'category': category,
        'place': place,
        'time': time,
        'reason': reason,
        'status': status,
        'createdAt': _ms(createdAt),
      };

  factory MatchRec.fromMap(Map<String, dynamic> m) => MatchRec(
        id: m['id'] as String,
        lostReportId: (m['lostReportId'] as String?) ?? '',
        foundReportId: (m['foundReportId'] as String?) ?? '',
        lostUserId: (m['lostUserId'] as String?) ?? '',
        foundUserId: (m['foundUserId'] as String?) ?? '',
        score: ((m['score'] as num?) ?? 0).toDouble(),
        text: ((m['text'] as num?) ?? 0).toDouble(),
        category: ((m['category'] as num?) ?? 0).toDouble(),
        place: ((m['place'] as num?) ?? 0).toDouble(),
        time: ((m['time'] as num?) ?? 0).toDouble(),
        reason: (m['reason'] as String?) ?? '',
        status: (m['status'] as String?) ?? 'suggested',
        createdAt: _dt(m['createdAt']),
      );
}

class Claim {
  const Claim({
    required this.id,
    required this.foundReportId,
    required this.foundTitle,
    required this.claimantId,
    required this.finderId,
    required this.answers,
    this.note = '',
    this.status = 'pending',
    this.requiresAdmin = false,
    this.handoverCode,
    this.reviewerId,
    required this.createdAt,
    this.decidedAt,
  });

  final String id;
  final String foundReportId;
  final String foundTitle;
  final String claimantId;
  final String finderId;
  final List<String> answers;
  final String note;

  /// pending, approved, rejected, withdrawn or completed.
  final String status;
  final bool requiresAdmin;
  final String? handoverCode;
  final String? reviewerId;
  final DateTime createdAt;
  final DateTime? decidedAt;

  bool get pending => status == 'pending';
  bool get approved => status == 'approved';

  Map<String, dynamic> toMap() => {
        'id': id,
        'foundReportId': foundReportId,
        'foundTitle': foundTitle,
        'claimantId': claimantId,
        'finderId': finderId,
        'answers': answers,
        'note': note,
        'status': status,
        'requiresAdmin': requiresAdmin,
        'handoverCode': handoverCode,
        'reviewerId': reviewerId,
        'createdAt': _ms(createdAt),
        'decidedAt': decidedAt == null ? null : _ms(decidedAt!),
      };

  factory Claim.fromMap(Map<String, dynamic> m) => Claim(
        id: m['id'] as String,
        foundReportId: (m['foundReportId'] as String?) ?? '',
        foundTitle: (m['foundTitle'] as String?) ?? '',
        claimantId: (m['claimantId'] as String?) ?? '',
        finderId: (m['finderId'] as String?) ?? '',
        answers: _strings(m['answers']),
        note: (m['note'] as String?) ?? '',
        status: (m['status'] as String?) ?? 'pending',
        requiresAdmin: (m['requiresAdmin'] as bool?) ?? false,
        handoverCode: m['handoverCode'] as String?,
        reviewerId: m['reviewerId'] as String?,
        createdAt: _dt(m['createdAt']),
        decidedAt: m['decidedAt'] == null ? null : _dt(m['decidedAt']),
      );
}

class Notice {
  const Notice({
    required this.id,
    required this.userId,
    required this.kind,
    required this.title,
    required this.body,
    this.refId,
    this.reportId,
    this.read = false,
    required this.createdAt,
  });

  final String id;
  final String userId;

  /// match, claim, handover or reminder.
  final String kind;
  final String title;
  final String body;
  final String? refId;
  final String? reportId;
  final bool read;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'kind': kind,
        'title': title,
        'body': body,
        'refId': refId,
        'reportId': reportId,
        'read': read,
        'createdAt': _ms(createdAt),
      };

  factory Notice.fromMap(Map<String, dynamic> m) => Notice(
        id: m['id'] as String,
        userId: (m['userId'] as String?) ?? '',
        kind: (m['kind'] as String?) ?? 'match',
        title: (m['title'] as String?) ?? '',
        body: (m['body'] as String?) ?? '',
        refId: m['refId'] as String?,
        reportId: m['reportId'] as String?,
        read: (m['read'] as bool?) ?? false,
        createdAt: _dt(m['createdAt']),
      );
}

class FlagRec {
  const FlagRec({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.targetUserId,
    required this.reporterId,
    required this.reason,
    required this.summary,
    this.status = 'open',
    required this.createdAt,
  });

  final String id;

  /// report, user or ai.
  final String targetType;
  final String targetId;
  final String targetUserId;
  final String reporterId;
  final String reason;
  final String summary;
  final String status;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'targetType': targetType,
        'targetId': targetId,
        'targetUserId': targetUserId,
        'reporterId': reporterId,
        'reason': reason,
        'summary': summary,
        'status': status,
        'createdAt': _ms(createdAt),
      };

  factory FlagRec.fromMap(Map<String, dynamic> m) => FlagRec(
        id: m['id'] as String,
        targetType: (m['targetType'] as String?) ?? 'report',
        targetId: (m['targetId'] as String?) ?? '',
        targetUserId: (m['targetUserId'] as String?) ?? '',
        reporterId: (m['reporterId'] as String?) ?? '',
        reason: (m['reason'] as String?) ?? '',
        summary: (m['summary'] as String?) ?? '',
        status: (m['status'] as String?) ?? 'open',
        createdAt: _dt(m['createdAt']),
      );
}
