import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

/// Accessible numeric keypad with minimum 56x56 targets, clear semantic announcements,
/// and responsive layout adapting cleanly to large text scaling.
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onDeletePressed,
    this.leftActionWidget,
  });

  final ValueChanged<String> onDigitPressed;
  final VoidCallback onDeletePressed;
  final Widget? leftActionWidget;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(['1', '2', '3']),
          const SizedBox(height: 12),
          _buildRow(['4', '5', '6']),
          const SizedBox(height: 12),
          _buildRow(['7', '8', '9']),
          const SizedBox(height: 12),
          _buildBottomRow(),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildKey(d)).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: leftActionWidget != null
              ? Center(child: leftActionWidget)
              : const SizedBox.shrink(),
        ),
        _buildKey('0'),
        SizedBox(
          width: 72,
          height: 72,
          child: Center(
            child: Semantics(
              button: true,
              label: 'Delete last digit',
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onDeletePressed();
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.backspace_outlined,
                      size: 26,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKey(String digit) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Center(
        child: Semantics(
          button: true,
          label: 'Digit $digit',
          child: Material(
            color: Colors.white.withValues(alpha: 0.85),
            shape: const CircleBorder(),
            elevation: 1.0,
            shadowColor: AppColors.shadowMedium.withValues(alpha: 0.1),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.lightImpact();
                onDigitPressed(digit);
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.borderLight,
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  digit,
                  style: AppTypography.display.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
