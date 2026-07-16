import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'models/user_profile.dart';
import 'screens/chat_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';

/// Top-level router.
///
/// Flow:
///   not signed in            -> LoginScreen
///   signed in, no profile    -> create profile, then re-evaluate
///   profile, onboarding !done -> OnboardingScreen
///   profile, onboarding done -> ChatScreen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        return StreamBuilder<UserProfile>(
          stream: firestoreService.watchUserProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            var profile = profileSnapshot.data;

            // First-time sign-in: no Firestore doc yet. Create one, then
            // let the stream re-fire with real data.
            if (profile == null || profile.email.isEmpty) {
              firestoreService.createUserProfile(
                UserProfile.newUser(
                  uid: user.uid,
                  email: user.email ?? '',
                  displayName: user.displayName ?? '',
                  photoUrl: user.photoURL ?? '',
                ),
              );
              return const _LoadingScreen();
            }

            if (!profile.onboardingComplete) {
              return OnboardingScreen(uid: user.uid);
            }

            return ChatScreen(profile: profile);
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
