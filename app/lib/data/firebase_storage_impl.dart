import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'storage.dart';

class FirestoreStorage implements Storage {
  FirestoreStorage() : _db = FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Query<Map<String, dynamic>> _q(String c, String? where, Object? equals) {
    final ref = _db.collection(c);
    return where == null ? ref : ref.where(where, isEqualTo: equals);
  }

  Row _row(DocumentSnapshot<Map<String, dynamic>> d) =>
      {...?d.data(), 'id': d.id};

  @override
  Stream<List<Row>> watch(String collection, {String? where, Object? equals}) =>
      _q(collection, where, equals)
          .snapshots()
          .map((s) => [for (final d in s.docs) _row(d)]);

  @override
  Future<List<Row>> query(String collection,
      {String? where, Object? equals}) async {
    final s = await _q(collection, where, equals).get();
    return [for (final d in s.docs) _row(d)];
  }

  @override
  Future<Row?> get(String collection, String id) async {
    final d = await _db.collection(collection).doc(id).get();
    return d.exists ? _row(d) : null;
  }

  @override
  Future<void> put(String collection, String id, Row data) =>
      _db.collection(collection).doc(id).set({...data, 'id': id});

  @override
  Future<void> update(String collection, String id, Row patch) =>
      _db.collection(collection).doc(id).update(patch);

  @override
  Future<void> remove(String collection, String id) =>
      _db.collection(collection).doc(id).delete();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService() : _auth = FirebaseAuth.instance;

  final FirebaseAuth _auth;

  AuthUser? _map(User? u) =>
      u == null ? null : AuthUser(u.uid, u.email ?? '', anonymous: u.isAnonymous);

  AuthFailure _fail(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return AuthFailure('That email address does not look right.');
      case 'email-already-in-use':
        return AuthFailure('An account with this email already exists.');
      case 'weak-password':
        return AuthFailure('Use a password with at least 8 characters.');
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return AuthFailure('Wrong email or password.');
      case 'network-request-failed':
        return AuthFailure('No internet connection. Try again.');
      case 'operation-not-allowed':
        return AuthFailure(
            'This sign-in method is not turned on in Firebase yet.');
      default:
        return AuthFailure(e.message ?? 'Sign-in failed (${e.code}).');
    }
  }

  @override
  AuthUser? get current => _map(_auth.currentUser);

  @override
  Stream<AuthUser?> get changes => _auth.authStateChanges().map(_map);

  @override
  Future<AuthUser> signUp(String email, String password) async {
    try {
      final c = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      try {
        await c.user?.sendEmailVerification();
      } catch (_) {
        // The account is created even if the verification email fails.
      }
      return _map(c.user)!;
    } on FirebaseAuthException catch (e) {
      throw _fail(e);
    }
  }

  @override
  Future<AuthUser> signIn(String email, String password) async {
    try {
      final c = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      return _map(c.user)!;
    } on FirebaseAuthException catch (e) {
      throw _fail(e);
    }
  }

  @override
  Future<AuthUser> signInGuest() async {
    try {
      final c = await _auth.signInAnonymously();
      return _map(c.user)!;
    } on FirebaseAuthException catch (e) {
      throw _fail(e);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthFailure(
            'For safety, sign out and sign in again, then delete your account.');
      }
      throw _fail(e);
    }
  }
}
