import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// Wraps Firebase Auth + Google/Facebook sign-in flows.
///
/// Web uses signInWithPopup for both providers instead of the native
/// plugin flows. Reason: on web, both `google_sign_in` and
/// `flutter_facebook_auth` can fall back to a full-page OAuth redirect
/// through Firebase's `__/auth/handler` page. That redirect round trip
/// depends on a `sessionStorage` flag surviving the trip to the IdP and
/// back — which browsers with storage partitioning (Chrome's default
/// now, Safari ITP) frequently drop, producing:
///   "Unable to process request due to missing initial state."
/// signInWithPopup avoids this because the app's page never navigates
/// away; the popup communicates back over postMessage instead.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Signs in with Google. Returns the FirebaseAuth [UserCredential],
  /// from which callers can check `additionalUserInfo?.isNewUser`.
  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      return _auth.signInWithPopup(provider);
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  /// Signs in with Facebook. Returns the FirebaseAuth [UserCredential].
  Future<UserCredential?> signInWithFacebook() async {
    if (kIsWeb) {
      final provider = FacebookAuthProvider();
      provider.addScope('email');
      return _auth.signInWithPopup(provider);
    }

    final result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );

    if (result.status != LoginStatus.success || result.accessToken == null) {
      return null;
    }

    final credential = FacebookAuthProvider.credential(
      result.accessToken!.tokenString,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      if (!kIsWeb) _googleSignIn.signOut(),
      if (!kIsWeb) FacebookAuth.instance.logOut(),
    ]);
  }
}
