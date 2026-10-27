// The app talks to data only through these two interfaces, so local storage
// (used when Firebase is not configured) and Firebase are interchangeable.

typedef Row = Map<String, dynamic>;

abstract class Storage {
  /// Live list of documents in [collection], optionally where [where] == [equals].
  Stream<List<Row>> watch(String collection, {String? where, Object? equals});

  Future<List<Row>> query(String collection, {String? where, Object? equals});
  Future<Row?> get(String collection, String id);
  Future<void> put(String collection, String id, Row data);
  Future<void> update(String collection, String id, Row patch);
  Future<void> remove(String collection, String id);
}

class AuthUser {
  const AuthUser(this.uid, this.email, {this.anonymous = false});
  final String uid;
  final String email;
  final bool anonymous;
}

class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class AuthService {
  AuthUser? get current;
  Stream<AuthUser?> get changes;
  Future<AuthUser> signUp(String email, String password);
  Future<AuthUser> signIn(String email, String password);
  Future<AuthUser> signInGuest();
  Future<void> signOut();
  Future<void> deleteAccount();
}
