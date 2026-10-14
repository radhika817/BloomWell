import 'package:flutter/material.dart';

/// Spacing and radius constants for consistent layout across BloomWell.
abstract class AppSpacing {
  // Padding & Margin increments
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;

  // Screen horizontal padding
  static const double screenHorizontal = 20.0;

  // Border radius values
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 22.0;
  static const double radiusXl = 28.0;
  static const double radiusPill = 999.0;

  // Reusable BorderRadius instances
  static const BorderRadius roundedSm =
      BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius roundedMd =
      BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg =
      BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedXl =
      BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius roundedPill =
      BorderRadius.all(Radius.circular(radiusPill));

  // Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(20.0);
  static const EdgeInsets cardPaddingSm = EdgeInsets.all(14.0);
}
