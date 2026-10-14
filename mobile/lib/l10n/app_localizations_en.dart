// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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

  @override
  String get avatarInitials => 'BW';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty =>
      'You are all caught up! No new notifications right now. 🌸';

  @override
  String get notificationsClose => 'Close';

  @override
  String get filterAll => 'All';

  @override
  String get filterCalm => 'Calm';

  @override
  String get filterEnergy => 'Energy';

  @override
  String get filterSleep => 'Sleep';

  @override
  String get filterFocus => 'Focus';

  @override
  String get filterMovement => 'Movement';

  @override
  String get featuredHeading => 'Featured for You';

  @override
  String get featuredBreathingTitle => 'Deep Breathing';

  @override
  String get featuredBreathingSubtitle => '2 min soothing rhythm';

  @override
  String get featuredBodyScanTitle => 'Body Scan & Unwind';

  @override
  String get featuredBodyScanSubtitle => '5 min gentle tension release';

  @override
  String get featuredJournalTitle => 'Mindful Journal';

  @override
  String get featuredJournalSubtitle => 'Express your thoughts safely';

  @override
  String get featuredStretchTitle => 'Gentle Stretch';

  @override
  String get featuredStretchSubtitle => 'Release back and neck tension';

  @override
  String get featuredSleepTitle => 'Nighttime Wind Down';

  @override
  String get featuredSleepSubtitle => 'Soft soothing sleep sounds';

  @override
  String get reminderTitle => 'Little Reminder';

  @override
  String get reminderBody =>
      'Drink a glass of water and take a deep breath. You are doing great today.';

  @override
  String get cyclePreviewTitle => 'Cycle & Body Rhythm';

  @override
  String get cyclePreviewBadge => 'Educational';

  @override
  String get cyclePreviewSubtitle => 'Understand your natural flow';

  @override
  String get cyclePreviewTip =>
      'Today\'s gentle tip: Stay hydrated and rest when your body asks.';

  @override
  String get cyclePreviewDisclaimer =>
      'Cycle insights are personal suggestions and never medical diagnoses.';

  @override
  String get breatheScreenTitle => 'Mindful Breathing';

  @override
  String get breatheScreenSubtitle => '8 soothing cycles · ~2 min';

  @override
  String breatheRemainingLabel(int seconds) {
    return '${seconds}s remaining';
  }

  @override
  String get breathePhaseInhale => 'Breathe In';

  @override
  String get breathePhaseHold => 'Hold Softly';

  @override
  String get breathePhaseExhale => 'Breathe Out';

  @override
  String get breathePhaseRest => 'Rest & Center';

  @override
  String get breathePlay => 'Play';

  @override
  String get breathePause => 'Pause';

  @override
  String get breatheFinish => 'Finish';

  @override
  String get breatheCompletedTitle => 'Session Complete 🌸';

  @override
  String get breatheCompletedMessage =>
      'Wonderful job taking this peaceful moment for your mind and body.';

  @override
  String get breatheReturnHome => 'Return to Home';

  @override
  String get breatheRestart => 'Breathe Again';

  @override
  String get breatheNonDiagnosticNote =>
      'Non-diagnostic relaxation exercise. Stop anytime if you feel lightheaded.';

  @override
  String get myMoodTitle => 'My Mood';

  @override
  String get myMoodEmptyTitle => 'Check in with your feelings';

  @override
  String get myMoodEmptySubtitle =>
      'Notice how your body and emotions feel today. Your reflections are private and never leave your phone.';

  @override
  String get myMoodCheckInButton => 'Check In on Home';

  @override
  String get myMoodPrivacyNote => 'Strictly on-device · No tracking';

  @override
  String get welcomeTitle => 'Welcome to BloomWell';

  @override
  String get welcomeSubtitle =>
      'A gentle, private wellness companion made for students.';

  @override
  String get welcomeFeature1Title => 'Privacy First';

  @override
  String get welcomeFeature1Desc =>
      'Your journal, mood, and cycle reflections are private and owner-scoped.';

  @override
  String get welcomeFeature2Title => 'Calm & Supportive';

  @override
  String get welcomeFeature2Desc =>
      'Gentle pacing, mindful breathing, and non-judgmental comfort.';

  @override
  String get welcomeFeature3Title => 'Academic Pacing';

  @override
  String get welcomeFeature3Desc =>
      'Cycle-aware, exam-aware suggestions to pace study and rest.';

  @override
  String get welcomeCta => 'Explore BloomWell';

  @override
  String get debugPreviewWelcome => 'Preview Welcome Screen (Debug)';
}
