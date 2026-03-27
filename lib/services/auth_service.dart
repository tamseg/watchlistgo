import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthService {
  Stream<User?> get authStateChanges;

  User? get currentUser;

  Future<UserCredential> signInWithGoogle();

  Future<void> signOut();

  Future<void> deleteAccount();
}
