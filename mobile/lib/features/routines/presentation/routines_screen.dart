import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/bloom_background.dart';
import '../../../../core/widgets/bloom_button.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:bloomwell/features/app_lock/application/app_lock_notifier.dart';
import '../application/routines_notifier.dart';
import 'widgets/create_edit_routine_dialog.dart';
import 'widgets/routine_card.dart';

/// Screen displaying the user's routines with gentle pacing, item scheduling,
/// and strict 20-routine limit enforcement.
class RoutinesScreen extends ConsumerStatefulWidget {
  const RoutinesScreen({super.key});

  @override
  ConsumerState<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends ConsumerState<RoutinesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(routinesNotifierProvider.notifier).loadRoutines();
    });
  }

  void _openCreateDialog(BuildContext context, RoutinesNotifier notifier) {
    CreateEditRoutineDialog.show(
      context,
      onSave: (title, startDate, endDate) async {
        await notifier.createRoutine(
          title: title,
          startDate: startDate,
          endDate: endDate,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(appLockNotifierProvider).isLocked;
    if (isLocked) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final l10n = AppLocalizations.of(context);
    final routinesState = ref.watch(routinesNotifierProvider);
    final notifier = ref.read(routinesNotifierProvider.notifier);
    final routines = routinesState.routines;
    final isMaxRoutinesReached = routines.length >= 20;

    return Scaffold(
      body: BloomBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  // Header Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          tooltip: l10n?.activityStepBack ?? 'Back',
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              context.go('/self-care');
                            }
                          },
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.routinesTitle ?? 'Routines',
                                style: AppTypography.titleLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                l10n?.routinesSubtitle ??
                                    'Gentle rituals to nourish your rhythm without pressure.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        BloomButton(
                          label: l10n?.routinesNewButton ?? 'New routine',
                          icon: Icons.add_rounded,
                          height: 38.0,
                          onPressed: isMaxRoutinesReached
                              ? null
                              : () => _openCreateDialog(context, notifier),
                        ),
                      ],
                    ),
                  ),

                  // 20-Routines Limit Notice
                  if (isMaxRoutinesReached)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                        vertical: AppSpacing.xs,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFCCC7)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: Color(0xFFD32F2F),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                l10n?.routinesLimitExceeded ??
                                    'You have reached the maximum limit of 20 routines.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: const Color(0xFFD32F2F),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: AppSpacing.xs),

                  // Content
                  Expanded(
                    child: routinesState.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryPurple,
                              ),
                            ),
                          )
                        : routinesState.errorMessage != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.xl),
                                  child: GlassCard(
                                    padding:
                                        const EdgeInsets.all(AppSpacing.lg),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🌧️',
                                            style: TextStyle(fontSize: 32)),
                                        const SizedBox(height: AppSpacing.sm),
                                        Text(
                                          routinesState.errorMessage!,
                                          textAlign: TextAlign.center,
                                          style: AppTypography.bodyMedium,
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        BloomButton(
                                          label: l10n?.selfCareRetry ??
                                              'Try again',
                                          onPressed: () =>
                                              notifier.loadRoutines(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : routines.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.all(AppSpacing.xl),
                                      child: GlassCard(
                                        padding:
                                            const EdgeInsets.all(AppSpacing.xl),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('🌿',
                                                style: TextStyle(fontSize: 40)),
                                            const SizedBox(
                                                height: AppSpacing.md),
                                            Text(
                                              l10n?.routinesEmptyTitle ??
                                                  'No routines created yet',
                                              textAlign: TextAlign.center,
                                              style: AppTypography.titleSmall
                                                  .copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(
                                                height: AppSpacing.xs),
                                            Text(
                                              l10n?.routinesEmptySubtitle ??
                                                  'Create a soothing daily or weekly routine that feels good to you.',
                                              textAlign: TextAlign.center,
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                color: AppColors.secondaryText,
                                              ),
                                            ),
                                            const SizedBox(
                                                height: AppSpacing.lg),
                                            BloomButton(
                                              label: l10n?.routinesNewButton ??
                                                  'New routine',
                                              icon: Icons.add_rounded,
                                              onPressed: () =>
                                                  _openCreateDialog(
                                                      context, notifier),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.screenHorizontal,
                                      vertical: AppSpacing.sm,
                                    ),
                                    itemCount: routines.length,
                                    itemBuilder: (context, index) {
                                      final routine = routines[index];
                                      return RoutineCard(routine: routine);
                                    },
                                  ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
