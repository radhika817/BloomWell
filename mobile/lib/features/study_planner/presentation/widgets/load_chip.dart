import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/suggested_load.dart';

/// Accessible load chip communicating study load via both icon AND text (never color alone).
class LoadChip extends StatelessWidget {
  const LoadChip({
    super.key,
    required this.load,
    this.isSelected = false,
    this.onTap,
  });

  final SuggestedLoad load;
  final bool isSelected;
  final VoidCallback? onTap;

  IconData get _icon {
    switch (load) {
      case SuggestedLoad.light:
        return Icons.spa_rounded;
      case SuggestedLoad.normal:
        return Icons.balance_rounded;
      case SuggestedLoad.focus:
        return Icons.psychology_rounded;
    }
  }

  String _label(AppLocalizations l10n) {
    switch (load) {
      case SuggestedLoad.light:
        return l10n.studyPlannerLoadLight;
      case SuggestedLoad.normal:
        return l10n.studyPlannerLoadNormal;
      case SuggestedLoad.focus:
        return l10n.studyPlannerLoadFocus;
    }
  }

  Color get _backgroundColor {
    switch (load) {
      case SuggestedLoad.light:
        return const Color(0xFFE8F5E9); // Soft gentle mint
      case SuggestedLoad.normal:
        return const Color(0xFFFFF8E1); // Soft gentle amber
      case SuggestedLoad.focus:
        return const Color(0xFFF3E5F5); // Soft lavender
    }
  }

  Color get _textColor {
    switch (load) {
      case SuggestedLoad.light:
        return const Color(0xFF2E7D32); // Deep forest green
      case SuggestedLoad.normal:
        return const Color(0xFFE65100); // Deep amber
      case SuggestedLoad.focus:
        return AppColors.deepPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = l10n != null ? _label(l10n) : load.name;

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isSelected ? _textColor : _textColor.withValues(alpha: 0.3),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon,
            size: 15.0,
            color: _textColor,
          ),
          const SizedBox(width: 5.0),
          Text(
            text,
            style: AppTypography.labelMedium.copyWith(
              color: _textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: chip,
      );
    }
    return chip;
  }
}
