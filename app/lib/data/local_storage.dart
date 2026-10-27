import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'storage.dart';

// Phone-only storage used when Firebase is not configured. Everything is kept
// in one JSON string inside shared preferences.
class LocalStorage implements Storage {
  LocalStorage._(this._prefs, this._db);

  static const _key = 'foundit_local_db';

  final SharedPreferences _prefs;
  final Map<String, Map<String, Row>> _db;
  final _changes = StreamController<void>.broadcast();

  static Future<LocalStorage> open() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final db = <String, Map<String, Row>>{};
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      decoded.forEach((collection, docs) {
        db[collection] = {
          for (final e in (docs as Map<String, dynamic>).entries)
            e.key: Map<String, dynamic>.from(e.value as Map),
        };
      });
    }
    return LocalStorage._(prefs, db);
  }

  bool get isEmpty => _db.isEmpty;

  Future<void> _save() async {
    await _prefs.setString(_key, jsonEncode(_db));
    _changes.add(null);
  }

  List<Row> _run(String collection, String? where, Object? equals) {
    final docs = _db[collection]?.values ?? const <Row>[];
    return [
      for (final d in docs)
        if (where == null || d[where] == equals) Map<String, dynamic>.from(d),
    ];
  }

  @override
  Stream<List<Row>> watch(String collection,
      {String? where, Object? equals}) async* {
    yield _run(collection, where, equals);
    await for (final _ in _changes.stream) {
      yield _run(collection, where, equals);
    }
  }

  @override
  Future<List<Row>> query(String collection,
          {String? where, Object? equals}) async =>
      _run(collection, where, equals);

  @override
  Future<Row?> get(String collection, String id) async {
    final d = _db[collection]?[id];
    return d == null ? null : Map<String, dynamic>.from(d);
  }

  @override
  Future<void> put(String collection, String id, Row data) async {
    (_db[collection] ??= {})[id] = {...data, 'id': id};
    await _save();
  }

  @override
  Future<void> update(String collection, String id, Row patch) async {
    final existing = _db[collection]?[id];
    if (existing == null) return;
    existing.addAll(patch);
    await _save();
  }

  @override
  Future<void> remove(String collection, String id) async {
    _db[collection]?.remove(id);
    await _save();
  }
}

// Demo accounts for local mode only. Passwords stay on this phone and are not
// used when Firebase is configured.
class LocalAuth implements AuthService {
  LocalAuth(this._prefs) {
    final uid = _prefs.getString(_sessionKey);
    if (uid != null) {
      _current = AuthUser(uid, _emails[uid] ?? '');
    }
  }

  static const _accountsKey = 'foundit_local_accounts';
  static const _sessionKey = 'foundit_local_session';

  final SharedPreferences _prefs;
  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _current;

  Map<String, dynamic> get _accounts {
    final raw = _prefs.getString(_accountsKey);
    return raw == null ? {} : jsonDecode(raw) as Map<String, dynamic>;
  }

  Map<String, String> get _emails => {
        for (final e in _accounts.entries)
          e.key: (e.value as Map)['email'] as String,
      };

  @override
  AuthUser? get current => _current;

  @override
  Stream<AuthUser?> get changes => _controller.stream;

  void _set(AuthUser? u) {
    _current = u;
    if (u == null) {
      _prefs.remove(_sessionKey);
    } else {
      _prefs.setString(_sessionKey, u.uid);
    }
    _controller.add(u);
  }

  // A fixed hash (FNV-1a), so ids stay the same between app runs.
  String _uidFor(String email) {
    var h = 0x811c9dc5;
    for (final c in email.trim().toLowerCase().codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0xFFFFFFFF;
    }
    return 'local-${h.toRadixString(16)}';
  }

  @override
  Future<AuthUser> signUp(String email, String password) async {
    final accounts = _accounts;
    final uid = _uidFor(email);
    if (accounts.containsKey(uid)) {
      throw AuthFailure('An account with this email already exists.');
    }
    accounts[uid] = {'email': email.trim().toLowerCase(), 'password': password};
    await _prefs.setString(_accountsKey, jsonEncode(accounts));
    final user = AuthUser(uid, email.trim().toLowerCase());
    _set(user);
    return user;
  }

  @override
  Future<AuthUser> signIn(String email, String password) async {
    final accounts = _accounts;
    final uid = _uidFor(email);
    final acc = accounts[uid] as Map?;
    if (acc == null || acc['password'] != password) {
      throw AuthFailure('Wrong email or password.');
    }
    final user = AuthUser(uid, acc['email'] as String);
    _set(user);
    return user;
  }

  @override
  Future<AuthUser> signInGuest() async {
    const user = AuthUser('local-guest', '', anonymous: true);
    _set(user);
    return user;
  }

  @override
  Future<void> signOut() async => _set(null);

  @override
  Future<void> deleteAccount() async {
    final u = _current;
    if (u != null) {
      final accounts = _accounts..remove(u.uid);
      await _prefs.setString(_accountsKey, jsonEncode(accounts));
    }
    _set(null);
  }
}
