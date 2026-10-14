import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/decorative_badge.dart';

/// Supportive daily encouragement card with gentle pastel gradient
/// and decorative motifs.
class EncouragementCard extends StatefulWidget {
  const EncouragementCard({super.key});

  @override
  State<EncouragementCard> createState() => _EncouragementCardState();
}

class _EncouragementCardState extends State<EncouragementCard> {
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      gradient: const LinearGradient(
        colors: [
          Color(0xFFFFF0F5), // Blush pink
          Color(0xFFEEE5FF), // Lavender
          Color(0xFFFFF7F2), // Soft peach glow
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: const Color(0xFFEAD8F7),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const DecorativeBadge(
                label: 'Daily Bloom Thought',
                emoji: '🌸',
                backgroundColor: Colors.white,
                textColor: AppColors.deepPurple,
                borderColor: Color(0xFFE4D5F2),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  _isSaved
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  color:
                      _isSaved ? const Color(0xFFE56B85) : AppColors.mutedText,
                  size: 22,
                ),
                tooltip: _isSaved ? 'Saved to heart' : 'Save to heart',
                onPressed: () {
                  setState(() {
                    _isSaved = !_isSaved;
                  });
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isSaved
                            ? 'Saved to your heart for this session 💖'
                            : 'Removed from saved thoughts',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: AppColors.deepPurple,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppSpacing.roundedMd,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '"Give yourself credit for how far you\'ve come. Soft days and slow progress still count. You don\'t have to carry the whole world today."',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16.5,
              height: 1.5,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 14)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Remember to take a sip of water and rest your shoulders.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
