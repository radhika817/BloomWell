import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import 'widgets/breathing_card.dart';
import 'widgets/encouragement_card.dart';
import 'widgets/greeting_header.dart';
import 'widgets/mood_checkin_card.dart';
import 'widgets/self_care_section.dart';

/// The BloomWell Home Screen.
///
/// Features a soft, feminine, calming pastel UI with local mood check-in,
/// supportive daily thought, self-care routine shortcuts, and interactive
/// mindful breathing.
class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToJournal;
  final VoidCallback onNavigateToCycleCare;
  final VoidCallback onNavigateToBreathe;
  final VoidCallback onNavigateToBloomBuddy;

  const HomeScreen({
    super.key,
    required this.onNavigateToJournal,
    required this.onNavigateToCycleCare,
    required this.onNavigateToBreathe,
    required this.onNavigateToBloomBuddy,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BloomMood? _selectedMood;

  void _handleDiscreetInfo() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🛡️', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Discreet Mode by Default',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'BloomWell is built for privacy in real college life. In Phase 4, you will be able to lock the app with PIN/biometrics, hide switcher previews, and configure neutral notifications.',
                style: AppTypography.bodyMedium.copyWith(height: 1.5),
              ),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Got it 🌸',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.deepPurple,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1 & 2: Greeting & Subtitle
                  GreetingHeader(
                    onDiscreetToggle: _handleDiscreetInfo,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // 3: Selectable Moods (Happy, Calm, Okay, Sad, Stressed)
                  MoodCheckinCard(
                    selectedMood: _selectedMood,
                    onMoodChanged: (mood) {
                      setState(() {
                        _selectedMood = mood;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // 4: Daily Encouragement Card
                  const EncouragementCard(),
                  const SizedBox(height: AppSpacing.xxl),

                  // 5: Two-column Self-Care Section
                  SelfCareSection(
                    onNavigateToJournal: widget.onNavigateToJournal,
                    onNavigateToCycleCare: widget.onNavigateToCycleCare,
                    onNavigateToBreathe: widget.onNavigateToBreathe,
                    onNavigateToBloomBuddy: widget.onNavigateToBloomBuddy,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // 6: Mindful Breathing Card
                  const BreathingCard(),
                  const SizedBox(height: AppSpacing.xxl),

                  // Gentle Footer Motif
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          '🌸 · ☁️ · 🤍 · 🌙 · ✨',
                          style: TextStyle(
                            fontSize: 16,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'BloomWell · Gentle, private self-care',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
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
