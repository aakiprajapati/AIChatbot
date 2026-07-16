import 'package:cloud_firestore/cloud_firestore.dart';

/// Core user profile stored in Firestore at users/{uid}.
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final List<String> interests;
  final bool onboardingComplete;

  // Gamification fields
  final int points;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final List<String> badges;
  final int questionsAsked;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.interests,
    required this.onboardingComplete,
    this.points = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.badges = const [],
    this.questionsAsked = 0,
  });

  /// Level is derived from points, not stored directly, so thresholds
  /// can change without a migration.
  String get level {
    if (points >= 500) return 'Pro';
    if (points >= 150) return 'Explorer';
    return 'Beginner';
  }

  factory UserProfile.newUser({
    required String uid,
    required String email,
    required String displayName,
    required String photoUrl,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      interests: const [],
      onboardingComplete: false,
    );
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      interests: List<String>.from(map['interests'] ?? const []),
      onboardingComplete: map['onboardingComplete'] ?? false,
      points: map['points'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastActiveDate: (map['lastActiveDate'] as Timestamp?)?.toDate(),
      badges: List<String>.from(map['badges'] ?? const []),
      questionsAsked: map['questionsAsked'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'interests': interests,
      'onboardingComplete': onboardingComplete,
      'points': points,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate':
      lastActiveDate != null ? Timestamp.fromDate(lastActiveDate!) : null,
      'badges': badges,
      'questionsAsked': questionsAsked,
    };
  }

  UserProfile copyWith({
    List<String>? interests,
    bool? onboardingComplete,
    int? points,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    List<String>? badges,
    int? questionsAsked,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      interests: interests ?? this.interests,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      points: points ?? this.points,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      badges: badges ?? this.badges,
      questionsAsked: questionsAsked ?? this.questionsAsked,
    );
  }
}

/// Fixed catalog of interests offered during onboarding.
const List<String> kAvailableInterests = [
  'Tech',
  'Fitness',
  'Travel',
  'Food',
  'Finance',
  'Music',
  'Gaming',
  'Health',
];
