import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/bloom_background.dart';
import '../../../../core/widgets/bloom_button.dart';
import '../../../../core/widgets/decorative_badge.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/pill_chip.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:bloomwell/features/app_lock/application/app_lock_notifier.dart';
import '../application/academic_events_notifier.dart';
import 'widgets/add_edit_exam_dialog.dart';
import 'widgets/exam_event_card.dart';

/// Screen displaying upcoming and past academic milestones, deadlines, and exams
/// with neutral pacing, local calendar formatting, and study planner preview notice.
class ExamsScreen extends ConsumerStatefulWidget {
  const ExamsScreen({super.key});

  @override
  ConsumerState<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends ConsumerState<ExamsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(academicEventsNotifierProvider.notifier).loadEvents();
    });
  }

  void _openCreateDialog(
    BuildContext context,
    AcademicEventsNotifier notifier,
  ) {
    AddEditExamDialog.show(
      context,
      onSave: (clientId, title, eventDate, eventType) async {
        await notifier.createEvent(
          clientId: clientId,
          title: title,
          eventDate: eventDate,
          eventType: eventType,
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
    final eventsState = ref.watch(academicEventsNotifierProvider);
    final notifier = ref.read(academicEventsNotifierProvider.notifier);
    final visibleEvents = eventsState.visibleEvents;

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
                              context.go('/');
                            }
                          },
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.examsTitle ?? 'Exams & Deadlines',
                                style: AppTypography.titleLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                l10n?.examsSubtitle ??
                                    'Keep track of academic events so study suggestions can feel gentler.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        BloomButton(
                          label: l10n?.examsNewButton ?? 'Add milestone',
                          icon: Icons.add_rounded,
                          height: 38.0,
                          onPressed: () => _openCreateDialog(context, notifier),
                        ),
                      ],
                    ),
                  ),

                  // Study Planner Notice Banner
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                      vertical: AppSpacing.xs,
                    ),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            size: 20,
                            color: AppColors.primaryPurple,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              l10n?.examsPlannerNotice ??
                                  'Adding exams and deadlines lets BloomWell suggest gentler study plans later. This is optional.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.secondaryText,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          DecorativeBadge(
                            label:
                                l10n?.examsPlannerComingSoon ?? 'Coming soon',
                            backgroundColor:
                                AppColors.lavender.withValues(alpha: 0.6),
                            textColor: AppColors.deepPurple,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Upcoming / Past View Selector Chips
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                    ),
                    child: Row(
                      children: [
                        PillChip(
                          label: l10n?.examsTabUpcoming ?? 'Upcoming',
                          isSelected: !eventsState.showPast,
                          onTap: () {
                            if (eventsState.showPast) {
                              notifier.togglePastView();
                            }
                          },
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        PillChip(
                          label: l10n?.examsTabPast ?? 'Past',
                          isSelected: eventsState.showPast,
                          onTap: () {
                            if (!eventsState.showPast) {
                              notifier.togglePastView();
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Events List / States
                  Expanded(
                    child: eventsState.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryPurple,
                              ),
                            ),
                          )
                        : eventsState.errorMessage != null
                            ? SingleChildScrollView(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Center(
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
                                          eventsState.errorMessage!,
                                          textAlign: TextAlign.center,
                                          style: AppTypography.bodyMedium,
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        BloomButton(
                                          label: l10n?.selfCareRetry ??
                                              'Try again',
                                          onPressed: () => notifier.loadEvents(
                                              refresh: true),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : visibleEvents.isEmpty
                                ? SingleChildScrollView(
                                    padding:
                                        const EdgeInsets.all(AppSpacing.md),
                                    child: Center(
                                      child: GlassCard(
                                        padding:
                                            const EdgeInsets.all(AppSpacing.lg),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('📅',
                                                style: TextStyle(fontSize: 36)),
                                            const SizedBox(
                                                height: AppSpacing.sm),
                                            Text(
                                              eventsState.showPast
                                                  ? (l10n?.examsEmptyPast ??
                                                      'No past exams recorded.')
                                                  : (l10n?.examsEmptyUpcoming ??
                                                      'No upcoming exams or deadlines entered. Enjoy your free rhythm.'),
                                              textAlign: TextAlign.center,
                                              style: AppTypography.titleSmall
                                                  .copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (!eventsState.showPast) ...[
                                              const SizedBox(
                                                  height: AppSpacing.md),
                                              BloomButton(
                                                label: l10n?.examsNewButton ??
                                                    'Add deadline or exam',
                                                icon: Icons.add_rounded,
                                                onPressed: () =>
                                                    _openCreateDialog(
                                                        context, notifier),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.screenHorizontal,
                                      vertical: AppSpacing.xs,
                                    ),
                                    itemCount: visibleEvents.length,
                                    itemBuilder: (context, index) {
                                      final event = visibleEvents[index];
                                      return ExamEventCard(event: event);
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
