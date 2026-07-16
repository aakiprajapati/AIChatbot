import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

/// All Firestore reads/writes for user profiles and the leaderboard.
///
/// Firestore layout:
///   users/{uid}                -> UserProfile fields
///   users/{uid}/messages/{id}  -> chat history (optional, not required to run)
class FirestoreService {
  final CollectionReference<Map<String, dynamic>> _users =
  FirebaseFirestore.instance.collection('users');

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(uid, doc.data()!);
  }

  Future<void> createUserProfile(UserProfile profile) async {
    await _users.doc(profile.uid).set(profile.toMap());
  }

  Future<void> saveInterests(String uid, List<String> interests) async {
    await _users.doc(uid).update({
      'interests': interests,
      'onboardingComplete': true,
    });
  }

  Stream<UserProfile> watchUserProfile(String uid) {
    return _users.doc(uid).snapshots().map(
          (doc) => UserProfile.fromMap(uid, doc.data() ?? {}),
    );
  }

  /// Applies a full gamification update in one write (points, streak,
  /// badges, questionsAsked, lastActiveDate) to avoid partial-state bugs.
  Future<void> applyGamificationUpdate(
      String uid,
      Map<String, dynamic> updateFields,
      ) async {
    await _users.doc(uid).update(updateFields);
  }

  /// Top N users by points, for the leaderboard screen.
  Stream<List<UserProfile>> watchLeaderboard({int limit = 20}) {
    return _users
        .orderBy('points', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => UserProfile.fromMap(d.id, d.data()))
        .toList());
  }
}
