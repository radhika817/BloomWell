import 'package:flutter/material.dart';

/// BloomWell color palette defined in the design specification.
///
/// Aesthetic direction: cute, soft, feminine, pastel, calming, and premium.
abstract class AppColors {
  // Core specified palette
  static const Color background = Color(0xFFFFF7FC);
  static const Color blushPink = Color(0xFFFFF0F5);
  static const Color lavender = Color(0xFFEEE5FF);
  static const Color primaryPurple = Color(0xFFA77BDF);
  static const Color deepPurple = Color(0xFF72539C);
  static const Color peach = Color(0xFFFFE0D5);
  static const Color mint = Color(0xFFE0F3E8);
  static const Color primaryText = Color(0xFF40364F);

  // Surface and card colors
  static const Color cardSurface = Colors.white;
  static const Color surfaceElevated = Color(0xFFFCF9FD);

  // Text hierarchy
  static const Color secondaryText = Color(0xFF6E637D);
  static const Color mutedText = Color(0xFF988EA6);
  static const Color lightText = Color(0xFFB5ACC0);

  // Borders and subtle dividers
  static const Color borderLight = Color(0xFFF3E8F5);
  static const Color borderSubtle = Color(0xFFEBE0F0);
  static const Color divider = Color(0xFFF0E5F2);

  // Accent and motif colors
  static const Color sunshineYellow = Color(0xFFFFF2B2);
  static const Color softRose = Color(0xFFF8B4C4);
  static const Color softSky = Color(0xFFD8EEFF);

  // Mood colors
  static const Color moodHappy = Color(0xFFFFE6D6);
  static const Color moodCalm = Color(0xFFE0F3E8);
  static const Color moodOkay = Color(0xFFEEE5FF);
  static const Color moodSad = Color(0xFFDCEBFF);
  static const Color moodStressed = Color(0xFFFFF0F5);

  // Shadow colors
  static const Color shadow = Color(0x1272539C);
  static const Color shadowMedium = Color(0x1F72539C);
}
