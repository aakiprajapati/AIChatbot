import 'package:flutter/material.dart';
import '../models/user_profile.dart';

/// Compact horizontal strip showing level, points, and streak.
/// Meant to sit just below the app bar on the chat screen.
class StatsBar extends StatelessWidget {
  final UserProfile profile;
  const StatsBar({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stat(Icons.emoji_events_outlined, profile.level),
          _stat(Icons.star_outline, '${profile.points} pts'),
          _stat(Icons.local_fire_department_outlined,
              '${profile.currentStreak}-day streak'),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
