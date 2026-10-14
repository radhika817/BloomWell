import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography definitions for BloomWell.
///
/// Designed with rounded, friendly, calming proportions using
/// Nunito for rounded headings and Inter for crisp body readability,
/// with robust system fallbacks.
abstract class AppTypography {
  static const String headingFont = 'Nunito';
  static const String bodyFont = 'Inter';
  static const List<String> fontFallbacks = ['Inter', 'Nunito', 'sans-serif'];

  static const TextStyle display = TextStyle(
    fontFamily: headingFont,
    fontFamilyFallback: fontFallbacks,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryText,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: headingFont,
    fontFamilyFallback: fontFallbacks,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: headingFont,
    fontFamilyFallback: fontFallbacks,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
    letterSpacing: -0.2,
    height: 1.35,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: headingFont,
    fontFamilyFallback: fontFallbacks,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
    letterSpacing: 0,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: bodyFont,
    fontFamilyFallback: fontFallbacks,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryText,
    letterSpacing: 0.1,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: bodyFont,
    fontFamilyFallback: fontFallbacks,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
    letterSpacing: 0.1,
    height: 1.45,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: bodyFont,
    fontFamilyFallback: fontFallbacks,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedText,
    letterSpacing: 0.2,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: headingFont,
    fontFamilyFallback: fontFallbacks,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.deepPurple,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: headingFont,
    fontFamilyFallback: fontFallbacks,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.deepPurple,
    letterSpacing: 0.2,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: bodyFont,
    fontFamilyFallback: fontFallbacks,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.mutedText,
    letterSpacing: 0.2,
  );
}
