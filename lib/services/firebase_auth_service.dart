import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_service.dart';
import 'database_service.dart';

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final DatabaseService _databaseService;

  FirebaseAuthService(this._databaseService);

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.userChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn.instance.authenticate();

    final googleAuth = googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);

    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      if (userCredential.user != null) {
        await _databaseService.createUser(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          displayName: userCredential.user!.displayName,
          photoUrl: userCredential.user!.photoURL,
        );
      }
    }

    return userCredential;
  }

  @override
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      final uid = user.uid;

      try {
        await _databaseService.updateMessagingFid(uid: uid, fid: null);
      } catch (e) {
        debugPrint('Failed to clear FCM FID before account deletion: $e');
      }

      await _databaseService.deleteUser(uid);

      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          throw FirebaseAuthException(
            code: 'requires-recent-login',
            message:
                'For your security, please Unlink and Link your Google account again before forgetting your profile.',
          );
        }
        rethrow;
      }

      bool isGoogleDisconnected = false;
      try {
        await GoogleSignIn.instance.disconnect();
        isGoogleDisconnected = true;
      } catch (e) {
        debugPrint('Google disconnect failed, attempting fallback.');
      }
      if (!isGoogleDisconnected) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}
      }
      await _firebaseAuth.signOut();
    }
  }
}
