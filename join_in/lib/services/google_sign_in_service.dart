import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  GoogleSignInService._();
  static final GoogleSignInService instance = GoogleSignInService._();

  static bool _initialized = false;

  /// Returns true when Firebase has been initialized in `main`. The Google
  /// sign-in button is hidden behind this check so the app stays usable even
  /// before you run `flutterfire configure`.
  static bool get isConfigured => Firebase.apps.isNotEmpty;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize();
    _initialized = true;
  }

  /// Signs into Google + Firebase Auth and returns the Firebase ID token that
  /// the backend expects on `POST /auth/login/google`. Returns null if the
  /// user cancels the sign-in flow.
  Future<String?> signInAndGetIdToken() async {
    if (!isConfigured) {
      throw StateError('Firebase is not configured. Run `flutterfire configure`.');
    }
    await _ensureInitialized();

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }

    final googleIdToken = account.authentication.idToken;
    if (googleIdToken == null) {
      throw StateError('Google did not return an ID token.');
    }

    final credential = GoogleAuthProvider.credential(idToken: googleIdToken);
    final firebaseResult = await FirebaseAuth.instance.signInWithCredential(credential);
    final firebaseIdToken = await firebaseResult.user?.getIdToken(true);
    if (firebaseIdToken == null) {
      throw StateError('Firebase did not return an ID token.');
    }
    return firebaseIdToken;
  }

  Future<void> signOut() async {
    if (isConfigured) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    if (_initialized) {
      try {
        await GoogleSignIn.instance.disconnect();
      } catch (_) {}
    }
  }
}
