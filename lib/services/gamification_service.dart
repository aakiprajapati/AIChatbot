import '../models/user_profile.dart';

/// Pure logic for turning "user sent a meaningful chat message" into
/// a Firestore update map. Kept separate from FirestoreService so the
/// rules can be unit-tested without touching Firestore.
class GamificationService {
  static const int pointsPerMessage = 10;

  /// Badge catalog: id -> (label, predicate over the *new* profile state).
  static final Map<String, bool Function(UserProfile)> _badgeRules = {
    'first_question': (p) => p.questionsAsked >= 1,
    '5_questions': (p) => p.questionsAsked >= 5,
    '25_questions': (p) => p.questionsAsked >= 25,
    '3_day_streak': (p) => p.currentStreak >= 3,
    '7_day_streak': (p) => p.currentStreak >= 7,
    '30_day_streak': (p) => p.currentStreak >= 30,
    'explorer_level': (p) => p.level == 'Explorer',
    'pro_level': (p) => p.level == 'Pro',
  };

  static const Map<String, String> badgeLabels = {
    'first_question': 'First Question',
    '5_questions': '5 Questions Asked',
    '25_questions': '25 Questions Asked',
    '3_day_streak': '3-Day Streak',
    '7_day_streak': '7-Day Streak',
    '30_day_streak': '30-Day Streak',
    'explorer_level': 'Reached Explorer',
    'pro_level': 'Reached Pro',
  };

  /// Call this once per meaningful user message (e.g. not on empty
  /// input, not on the AI's own turn). Returns the Firestore update map
  /// AND the list of newly earned badge ids (for a celebratory UI toast).
  ({Map<String, dynamic> updateFields, List<String> newBadges})
  registerInteraction(UserProfile current) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int newStreak = current.currentStreak;
    if (current.lastActiveDate == null) {
      newStreak = 1;
    } else {
      final last = current.lastActiveDate!;
      final lastDay = DateTime(last.year, last.month, last.day);
      final dayDiff = today.difference(lastDay).inDays;

      if (dayDiff == 0) {
        // Already active today; streak unchanged.
        newStreak = current.currentStreak == 0 ? 1 : current.currentStreak;
      } else if (dayDiff == 1) {
        newStreak = current.currentStreak + 1;
      } else {
        newStreak = 1; // streak broken, restart
      }
    }

    final newLongest =
    newStreak > current.longestStreak ? newStreak : current.longestStreak;
    final newPoints = current.points + pointsPerMessage;
    final newQuestionsAsked = current.questionsAsked + 1;

    final prospective = current.copyWith(
      points: newPoints,
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastActiveDate: today,
      questionsAsked: newQuestionsAsked,
    );

    final newlyEarned = <String>[];
    for (final entry in _badgeRules.entries) {
      final alreadyHas = current.badges.contains(entry.key);
      if (!alreadyHas && entry.value(prospective)) {
        newlyEarned.add(entry.key);
      }
    }

    final updatedBadges = [...current.badges, ...newlyEarned];

    return (
    updateFields: {
      'points': newPoints,
      'currentStreak': newStreak,
      'longestStreak': newLongest,
      'lastActiveDate': today,
      'questionsAsked': newQuestionsAsked,
      'badges': updatedBadges,
    },
    newBadges: newlyEarned,
    );
  }
}
