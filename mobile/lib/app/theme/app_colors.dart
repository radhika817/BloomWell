import 'package:flutter/material.dart';

/// BloomWell color palette defined in the design specification.
///
/// Aesthetic direction: cute, soft glass, feminine, pastel, calming, and premium.
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

  // Soft Glass Background Gradient
  static const Color bgGradientStart = Color(0xFFF1E6FF);
  static const Color bgGradientMiddle = Color(0xFFFFE9F3);
  static const Color bgGradientEnd = Color(0xFFFFF7FC);

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [bgGradientStart, bgGradientMiddle, bgGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Frosted Glass Surfaces
  static const Color glassBackground = Color(0xB8FFFFFF); // ~72% opacity white
  static const Color glassBorder = Color(0x99FFFFFF); // ~60% opacity white
  static const Color glassBorderSubtle =
      Color(0x66FFFFFF); // ~40% opacity white
  static const Color glassBackgroundCard = Color(0xD0FFFFFF); // ~82% opacity

  // CTA Gradient
  static const Color ctaGradientStart = Color(0xFFB28AE8);
  static const Color ctaGradientEnd = Color(0xFF8F5FD1);

  static const LinearGradient ctaGradient = LinearGradient(
    colors: [ctaGradientStart, ctaGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color ctaShadow = Color(0x2E8F5FD1);

  // Surface and card colors
  static const Color cardSurface = Colors.white;
  static const Color surfaceElevated = Color(0xFFFCF9FD);
  static const Color softCardBorder = Color(0xFFF3EBF7);

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

  // Mood bubble pastel colors
  static const Color moodHappy = Color(0xFFFFE6D6);
  static const Color moodCalm = Color(0xFFE0F3E8);
  static const Color moodOkay = Color(0xFFEEE5FF);
  static const Color moodSad = Color(0xFFDCEBFF);
  static const Color moodStressed = Color(0xFFFFF0F5);

  // Shadow colors
  static const Color shadow = Color(0x1272539C);
  static const Color shadowMedium = Color(0x1F72539C);
  static const Color shadowGlow = Color(0x26B28AE8);
}
