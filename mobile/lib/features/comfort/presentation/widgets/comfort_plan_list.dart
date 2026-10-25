import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/bloom_button.dart';
import '../../../../core/widgets/decorative_badge.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:bloomwell/features/comfort/application/comfort_notifier.dart';
import 'package:bloomwell/features/comfort/domain/entities/comfort_plan_item.dart';

/// Reorderable, editable personal comfort plan list for Comfort Mode.
class ComfortPlanList extends ConsumerWidget {
  const ComfortPlanList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final comfortState = ref.watch(comfortNotifierProvider);
    final plan = comfortState.comfortPlan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.comfortPlanTitle ?? 'My comfort plan',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          l10n?.comfortPlanSubtitle ??
              'Your saved soothing practices for difficult days.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (comfortState.isLoadingPlan)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryPurple,
                ),
              ),
            ),
          )
        else if (plan.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const Text('🧸', style: TextStyle(fontSize: 32)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n?.comfortPlanEmpty ??
                      'No practices in your plan yet. Save a few favorites here for easy access.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                BloomButton(
                  label: l10n?.selfCareStudioTitle ?? 'Self-Care Studio',
                  icon: Icons.add_rounded,
                  variant: BloomButtonVariant.subtle,
                  onPressed: () => context.push('/self-care'),
                ),
              ],
            ),
          )
        else ...[
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: plan.length,
            // ignore: deprecated_member_use
            onReorder: (oldIndex, newIndex) {
              var adjustedIndex = newIndex;
              if (adjustedIndex > oldIndex) adjustedIndex -= 1;
              ref
                  .read(comfortNotifierProvider.notifier)
                  .reorderPlan(oldIndex, adjustedIndex);
            },
            itemBuilder: (context, index) {
              final item = plan[index];
              return _buildPlanItemTile(context, ref, item, index, l10n);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          BloomButton(
            label: l10n?.selfCareStudioTitle ?? 'Add from library',
            icon: Icons.add_rounded,
            variant: BloomButtonVariant.subtle,
            onPressed: () => context.push('/self-care'),
          ),
        ],
      ],
    );
  }

  Widget _buildPlanItemTile(
    BuildContext context,
    WidgetRef ref,
    ComfortPlanItem item,
    int index,
    AppLocalizations? l10n,
  ) {
    final activity = item.activity;
    final title = activity?.title ?? 'Comfort practice';
    final duration = activity?.durationMinutes ?? 5;
    final categoryName = activity?.category.name ?? 'comfort';
    final targetActivityId = activity?.id ?? item.activityId;

    return Padding(
      key: ValueKey(item.id),
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        onTap: () {
          if (targetActivityId.isNotEmpty) {
            context.push('/self-care/activity/$targetActivityId');
          }
        },
        child: Row(
          children: [
            // Drag Handle
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.only(right: AppSpacing.sm),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: AppColors.mutedText,
                  size: 20,
                ),
              ),
            ),
            // Title & duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      DecorativeBadge(
                        label: l10n?.selfCareDurationMinutes(duration) ??
                            '$duration min',
                        backgroundColor:
                            AppColors.lavender.withValues(alpha: 0.6),
                        textColor: AppColors.deepPurple,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        categoryName,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Remove Button
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.mutedText,
                size: 20,
              ),
              tooltip: l10n?.comfortRemoveFromPlan ?? 'Remove from plan',
              onPressed: () {
                ref
                    .read(comfortNotifierProvider.notifier)
                    .removeFromPlan(item.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
