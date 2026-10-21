import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/app_lock/application/app_lock_notifier.dart';
import '../features/app_lock/presentation/widgets/privacy_cover_widget.dart';
import '../features/auth/application/auth_notifier.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// The root application widget for BloomWell.
class BloomWellApp extends ConsumerStatefulWidget {
  const BloomWellApp({super.key});

  @override
  ConsumerState<BloomWellApp> createState() => _BloomWellAppState();
}

class _BloomWellAppState extends ConsumerState<BloomWellApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authNotifierProvider.notifier).restoreSession();
      await ref.read(appLockNotifierProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockNotifierProvider);

    return MaterialApp.router(
      title: 'BloomWell',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (BuildContext context, Widget? child) {
        if (lockState.isCovered) {
          return PrivacyCoverWidget(
            canDismissOnTap: !lockState.isLocked,
            onTapToDismiss: () {
              ref.read(appLockNotifierProvider.notifier).dismissCover();
            },
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
