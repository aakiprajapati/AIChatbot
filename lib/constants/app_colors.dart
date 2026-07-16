import 'package:flutter/material.dart';

/// Central place for every color used in the app. Import this instead of
/// hardcoding hex values or Colors.xyz in screens/widgets, so a rebrand
/// is a one-file change.
class AppColors {
  AppColors._(); // no instances

  // Brand
  static const Color seed = Color(0xFF6750A4); // deepPurple-ish seed
  static const Color primary = Color(0xFF6750A4);
  static const Color secondary = Color(0xFF625B71);

  // Social sign-in brand colors (kept exact — these are Facebook/Google
  // brand guidelines, not part of the app's own palette)
  static const Color facebookBlue = Color(0xFF1877F2);
  static const Color googleRed = Color(0xFFDB4437);

  // Gamification accents
  static const Color streakFlame = Color(0xFFFF7043);
  static const Color badgeGold = Color(0xFFFFC107);
  static const Color levelBeginner = Color(0xFF90A4AE);
  static const Color levelExplorer = Color(0xFF42A5F5);
  static const Color levelPro = Color(0xFFAB47BC);

  // Chat bubbles
  static const Color userBubble = primary;
  static const Color aiBubbleLight = Color(0xFFECE6F0);
  static const Color aiBubbleDark = Color(0xFF4A4458);

  // Status
  static const Color error = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF2E7D32);
}
