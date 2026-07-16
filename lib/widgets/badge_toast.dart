import 'package:flutter/material.dart';
import '../services/gamification_service.dart';

void showBadgeToast(BuildContext context, List<String> newBadgeIds) {
  for (final id in newBadgeIds) {
    final label = GamificationService.badgeLabels[id] ?? id;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.military_tech, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(child: Text('Badge unlocked: $label')),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
