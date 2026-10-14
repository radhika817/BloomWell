import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// The root application widget for BloomWell.
class BloomWellApp extends StatelessWidget {
  const BloomWellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const BloomWellNavigationShell(),
    );
  }
}
