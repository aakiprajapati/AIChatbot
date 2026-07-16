import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// Wraps Firebase Auth + Google/Facebook sign-in flows.
///
/// Web uses signInWithPopup for both providers instead of the native
/// plugin flows, to avoid Firebase's "missing initial state" error
/// caused by browser storage partitioning breaking the redirect flow.
///
/// google_sign_in v7 note: the plugin is now a singleton
/// (GoogleSignIn.instance) that must be initialize()'d exactly once
/// before use, and authentication/authorization are separate calls
/// (authenticate() replaces the old signIn(); the access token comes
/// from authorizationClient, not from the authentication result).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInInitialized = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    // Web client ID from Google Cloud Console > APIs & Services >
    // Credentials > OAuth 2.0 Client IDs > "Web client (auto created by
    // Google Service)". Required on Android so Credential Manager can
    // issue an ID token Firebase will accept.
    await _googleSignIn.initialize(
      serverClientId:
      '191370094637-50rj1oi2k60so3djtu2c9l4jhh02cb7l.apps.googleusercontent.com',
    );
    _googleSignInInitialized = true;
  }

  /// Signs in with Google. Returns the FirebaseAuth [UserCredential],
  /// or null if the user cancelled the flow.
  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      return _auth.signInWithPopup(provider);
    }

    await _ensureGoogleSignInInitialized();

    late final GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }

    // Authentication (identity) is synchronous in v7 and gives the ID
    // token. The access token is a separate authorization step.
    final idToken = googleUser.authentication.idToken;
    final authorization = await googleUser.authorizationClient
        .authorizationForScopes(['email']);

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: authorization?.accessToken,
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