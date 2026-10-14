// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appName => 'BloomWell';

  @override
  String get homeGreeting => 'Hey, lovely! 🌷';

  @override
  String get homeSubtitle => 'Take a little moment for yourself.';

  @override
  String get discreetBadge => 'Discreet';

  @override
  String get discreetSheetTitle => 'Discreet Mode (Planned)';

  @override
  String get discreetSheetBody =>
      'BloomWell is designed with privacy as a foundation. In a future update, you will be able to lock the app with PIN or biometrics, obscure switcher previews, and configure neutral notifications. Currently, this mode is planned and not yet active.';

  @override
  String get discreetSheetButton => 'Got it 🌸';

  @override
  String get moodQuestion => 'How are you feeling right now?';

  @override
  String get moodReset => 'Reset';

  @override
  String get moodHappy => 'Happy';

  @override
  String get moodCalm => 'Calm';

  @override
  String get moodOkay => 'Okay';

  @override
  String get moodSad => 'Sad';

  @override
  String get moodStressed => 'Stressed';

  @override
  String get moodHappyAffirmation =>
      'So glad you\'re feeling radiant today! Let this light nourish your day. ✨';

  @override
  String get moodCalmAffirmation =>
      'Cherish this peaceful energy. May your day stay gentle and unhurried. 🌿';

  @override
  String get moodOkayAffirmation =>
      'Steady and okay is wonderful. Honor wherever you are today. ☁️';

  @override
  String get moodSadAffirmation =>
      'It is okay to be gentle and slow today, darling. Sending warm thoughts. 🤍';

  @override
  String get moodStressedAffirmation =>
      'Take a slow, deep breath. You are capable and more than your worries. 💜';

  @override
  String get moodDisclaimer => 'Session check-in · Not persisted';

  @override
  String get moodSupportiveMessage =>
      'It looks like today might be a bit heavy. You don\'t have to carry it alone. Please be extra gentle with yourself.';

  @override
  String get tryComfortMode => 'Try Comfort Mode';

  @override
  String get findSupport => 'Find support';

  @override
  String get dailyEncouragementBadge => 'Daily Bloom Thought';

  @override
  String get dailyEncouragementQuote =>
      '\"Give yourself credit for how far you\'ve come. Soft days and slow progress still count. You don\'t have to carry the whole world today.\"';

  @override
  String get dailyEncouragementTip =>
      'Remember to take a sip of water and rest your shoulders.';

  @override
  String get bookmarkSessionTooltip => 'Bookmark for this session';

  @override
  String get bookmarkedFeedback => 'Thought bookmarked for this session 💖';

  @override
  String get unbookmarkedFeedback => 'Removed bookmark';

  @override
  String get planStudyWeekTitle => 'Plan my study week 📚';

  @override
  String get planStudyWeekSubtitle =>
      'Cycle-aware, exam-aware suggestions to pace your study and rest.';

  @override
  String get hardDayButtonLabel => 'I\'m having a hard day 🤍';

  @override
  String get comingSoonBadge => 'Coming soon';

  @override
  String get selfCareHeading => 'Self-Care Routines 🌿';

  @override
  String get selfCareSubtitle => 'Gentle rituals to nourish your body and mind';

  @override
  String get journalTitle => 'Journal';

  @override
  String get journalSubtitle => 'Private thoughts & feelings';

  @override
  String get journalBadge => 'Private';

  @override
  String get cycleCareTitle => 'CycleCare';

  @override
  String get cycleCareSubtitle => 'Symptom & cycle tracking';

  @override
  String get cycleCareBadge => 'Optional';

  @override
  String get breatheTitle => 'Breathe & Relax';

  @override
  String get breatheSubtitle => 'Guided grounding exercises';

  @override
  String get breatheBadge => 'about 2 min';

  @override
  String get bloomBuddyTitle => 'Bloom Buddy';

  @override
  String get bloomBuddySubtitle => 'Gentle companion';

  @override
  String get breathingCardTitle => 'Mindful Breathing';

  @override
  String get breathingCardSubtitle => 'Inhale peace, exhale tension';

  @override
  String get breathingDurationBadge => 'about 2 min';

  @override
  String breathingCycleCount(int current, int total) {
    return 'Cycle $current of $total';
  }

  @override
  String get breathingPhaseIdleTitle => 'Ready to relax';

  @override
  String get breathingPhaseIdleInstruction =>
      'Take a comfortable breath when you are ready';

  @override
  String get breathingPhaseInhaleTitle => 'Breathe In';

  @override
  String get breathingPhaseInhaleInstruction => 'Inhale peace and clarity...';

  @override
  String get breathingPhaseHoldInTitle => 'Hold Gently';

  @override
  String get breathingPhaseHoldInInstruction => 'Hold your breath softly...';

  @override
  String get breathingPhaseExhaleTitle => 'Breathe Out';

  @override
  String get breathingPhaseExhaleInstruction =>
      'Release all tightness and worries...';

  @override
  String get breathingPhaseHoldOutTitle => 'Rest';

  @override
  String get breathingPhaseHoldOutInstruction =>
      'Rest in this gentle stillness...';

  @override
  String get breathingStartButton => 'Start Quick Session';

  @override
  String get breathingPauseButton => 'Pause Exercise';

  @override
  String get footerMotifs => '🌸 · ☁️ · 🤍 · 🌙 · ✨';

  @override
  String get footerTagline => 'BloomWell · Gentle, private self-care';

  @override
  String get navHome => 'Home';

  @override
  String get navMood => 'My Mood';

  @override
  String get navCycleCare => 'CycleCare';

  @override
  String get navBloomBuddy => 'Bloom Buddy';

  @override
  String get navProfile => 'Profile';

  @override
  String get placeholderPlannedLabel => 'Coming in a later update';

  @override
  String get placeholderBackToHome => 'Back to Home';

  @override
  String get placeholderPlannedHeading => 'Planned Implementation';

  @override
  String get placeholderDisclaimer =>
      'BloomWell does not fabricate user records or mock health data. Real tracking begins when the local storage & API layers are integrated.';

  @override
  String get moodPlaceholderTitle => 'MoodMap & Insights';

  @override
  String get moodPlaceholderSubtitle =>
      'Understand your emotional patterns over time';

  @override
  String get moodPlaceholderDescription =>
      'MoodMap will provide historical charts, weekly reflections, and energy observations based on your daily check-ins. Today, you can try out the interactive mood selector directly on the Home screen.';

  @override
  String get cycleCarePlaceholderTitle => 'CycleCare';

  @override
  String get cycleCarePlaceholderSubtitle =>
      'Gentle, private menstrual and symptom logging';

  @override
  String get cycleCarePlaceholderDescription =>
      'CycleCare will allow you to log period dates, cramp severity, bloating, and fatigue. All cycle estimates will be clearly distinguished from recorded dates, strictly non-diagnostic, and stored securely.';

  @override
  String get bloomBuddyPlaceholderTitle => 'Bloom Buddy';

  @override
  String get bloomBuddyPlaceholderSubtitle =>
      'Your warm, consent-separated companion';

  @override
  String get bloomBuddyPlaceholderDescription =>
      'Bloom Buddy will bring together mindful reflections and peer care. Planned sections arriving in future updates include: AI Companion (with explicit consent), I\'m Here (gentle listening), Cycle Circles (moderated topic peer support), and HelpHub (verified campus access points).';

  @override
  String get profilePlaceholderTitle => 'Profile & Privacy Center';

  @override
  String get profilePlaceholderSubtitle =>
      'Complete control over your personal data';

  @override
  String get profilePlaceholderDescription =>
      'The Privacy Center will host Discreet Mode (app lock, neutral notifications), exportable Doctor-visit summaries, language selection (English, Hindi, Marathi), and full one-tap data deletion.';

  @override
  String get journalPlaceholderTitle => 'Private Journal';

  @override
  String get journalPlaceholderSubtitle =>
      'A safe, judgment-free space to write';

  @override
  String get journalPlaceholderDescription =>
      'Your journal entries will be encrypted, private by default, and never browsable by moderators or administrators. An on-device safety layer ensures gentle resources appear if distress language is detected.';

  @override
  String get breathePlaceholderTitle => 'Breathe & Relax';

  @override
  String get breathePlaceholderSubtitle =>
      'Gentle somatic calming & grounding exercises';

  @override
  String get breathePlaceholderDescription =>
      'Expanded audio sessions, 4-7-8 breathing techniques, progressive muscle relaxation, and warm compress reminders will be available here. For now, try out the mindful breathing exercise right on your Home screen!';

  @override
  String get comfortPlaceholderTitle => 'Comfort Mode';

  @override
  String get comfortPlaceholderSubtitle => 'Gentle care for difficult days';

  @override
  String get comfortPlaceholderDescription =>
      'Comfort Mode offers simplified, soothing routines, warm compress reminders, calming soundscapes, and non-diagnostic grounding prompts for when you are not feeling your best.';

  @override
  String get studyPlannerPlaceholderTitle => 'Study Planner';

  @override
  String get studyPlannerPlaceholderSubtitle =>
      'Cycle-aware, exam-aware academic pacing';

  @override
  String get studyPlannerPlaceholderDescription =>
      'The Study Planner suggests lighter or heavier study blocks and rest breaks around your own energy check-ins and entered exam dates — as gentle suggestions, never rigid predictions.';

  @override
  String get helpPlaceholderTitle => 'Support Resources & HelpHub';

  @override
  String get helpPlaceholderSubtitle =>
      'Verified campus care and period-product access';

  @override
  String get helpPlaceholderDescription =>
      'HelpHub connects you to verified campus dispensers, health center resources, helplines, and period-product access points with real verification dates and student reporting.';
}
