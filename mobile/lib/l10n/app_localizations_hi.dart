// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

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

  @override
  String get authSignIn => 'Sign In';

  @override
  String get authCreateAccount => 'Create Account';

  @override
  String get authRegister => 'Register';

  @override
  String get authLogin => 'Log In';

  @override
  String get authLogout => 'Log Out';

  @override
  String get authEmail => 'Email address';

  @override
  String get authEmailPlaceholder => 'you@campus.edu';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordPlaceholder => 'At least 10 characters';

  @override
  String get authPasswordConfirm => 'Confirm Password';

  @override
  String get authPasswordConfirmPlaceholder => 'Re-enter your password';

  @override
  String get authDisplayName => 'Display Name (optional)';

  @override
  String get authDisplayNamePlaceholder => 'What should we call you?';

  @override
  String get authTimezone => 'Timezone';

  @override
  String get authLoginPrompt => 'Already have an account? Sign In';

  @override
  String get authRegisterPrompt => 'Don\'t have an account? Create one';

  @override
  String get authLoginTitle => 'Welcome Back';

  @override
  String get authLoginSubtitle =>
      'Log in to access your gentle self-care space.';

  @override
  String get authRegisterTitle => 'Join BloomWell';

  @override
  String get authRegisterSubtitle =>
      'A private, supportive wellness sanctuary designed for students.';

  @override
  String get authPasswordMinLength => 'Password must be at least 10 characters';

  @override
  String get authPasswordMismatch => 'Passwords do not match';

  @override
  String get authEmailInvalid => 'Please enter a valid email address';

  @override
  String get authEmailRequired => 'Email is required';

  @override
  String get authPasswordRequired => 'Password is required';

  @override
  String get authErrorInvalidCredentials =>
      'Invalid email or password. Please check your credentials.';

  @override
  String get authErrorEmailAlreadyRegistered =>
      'An account with this email address already exists.';

  @override
  String authErrorRateLimited(int seconds) {
    return 'Too many attempts. Please wait $seconds seconds before trying again.';
  }

  @override
  String get authErrorGeneric =>
      'Something went wrong. Please check your connection and try again.';

  @override
  String get authLoggingIn => 'Logging in...';

  @override
  String get authRegistering => 'Creating your account...';

  @override
  String get authLoggingOut => 'Logging out...';

  @override
  String get authLogoutConfirmation => 'Are you sure you want to log out?';

  @override
  String get authLogoutCancel => 'Cancel';

  @override
  String get authLogoutConfirm => 'Log Out';

  @override
  String get discreetOnboardingTitle => 'Keep Your Space Discreet 🌸';

  @override
  String get discreetOnboardingBody =>
      'Many students share devices or live with roommates. You can add a quick PIN lock to shield your check-ins and journal notes from casual view.';

  @override
  String get discreetOnboardingSetupButton => 'Set Up PIN Lock';

  @override
  String get discreetOnboardingNotNowButton => 'Not Now';

  @override
  String get pinTooShortMessage => 'PIN must be 4 to 6 digits';

  @override
  String get pinWeakMessage =>
      'Please choose a stronger PIN (avoid 1234, 0000, or repeated digits)';

  @override
  String get pinMismatchMessage => 'PINs do not match. Try again';

  @override
  String get pinSetupSuccess => 'App lock PIN set successfully 🌸';

  @override
  String get pinConfirmTitle => 'Confirm Your PIN';

  @override
  String get pinCreateTitle => 'Set Up App Lock PIN';

  @override
  String get pinConfirmSubtitle => 'Re-enter your 4 to 6 digit PIN to confirm.';

  @override
  String get pinCreateSubtitle =>
      'Choose a 4 to 6 digit convenience PIN to shield your space.';

  @override
  String get pinSaveButton => 'Save PIN';

  @override
  String get pinContinueButton => 'Continue';

  @override
  String get appLockTitle => 'BloomWell Locked';

  @override
  String get appLockSubtitle => 'Enter your PIN to resume your gentle space.';

  @override
  String lockoutActiveMessage(int seconds) {
    return 'Too many failed attempts. Try again in $seconds seconds.';
  }

  @override
  String pinIncorrectAttempts(int attempts) {
    return 'Incorrect PIN. ($attempts failed attempts)';
  }

  @override
  String get biometricUnlockPrompt =>
      'Unlock BloomWell to access your private space';

  @override
  String get forgotPinDialogTitle => 'Forgot PIN?';

  @override
  String get forgotPinDialogBody =>
      'There is no server-side PIN recovery. To reset your PIN, you must log out. This will clear the PIN on this device and your local session. You can then log back in with your account password.';

  @override
  String get forgotPinCancel => 'Cancel';

  @override
  String get forgotPinLogoutConfirm => 'Log Out & Reset';

  @override
  String get biometricsButtonTooltip => 'Unlock with biometrics';

  @override
  String get unlockButtonLabel => 'Unlock';

  @override
  String get forgotPinButton => 'Forgot PIN?';

  @override
  String get privacyCenterTitle => 'Privacy Center';

  @override
  String get privacyHonestyTitle => 'How App Lock Works';

  @override
  String get privacyHonestyBody =>
      'This PIN is a convenience lock against casual access (like a roommate borrowing your phone). It does NOT encrypt device data. BloomWell records are stored safely on the BloomWell server under your account and are visible only to you.';

  @override
  String get appLockSectionHeading => 'App Lock & PIN';

  @override
  String get enableAppLockTitle => 'Enable App Lock';

  @override
  String get appLockActiveSubtitle => 'PIN configured and active';

  @override
  String get appLockInactiveSubtitle => 'Require PIN to open BloomWell';

  @override
  String get changePinTitle => 'Change PIN';

  @override
  String get biometricsToggleTitle => 'Unlock with Biometrics';

  @override
  String get biometricsToggleSubtitle =>
      'Use fingerprint or Face ID as quick fallback';

  @override
  String get biometricsUnavailable =>
      'Biometrics not available or not enrolled on this device.';

  @override
  String get webBiometricsNote => 'Biometrics unavailable on web';

  @override
  String get autoLockTimeoutLabel => 'Auto-lock timeout';

  @override
  String get screenPrivacyHeading => 'Screen Privacy';

  @override
  String get blockScreenshotsTitle => 'Hide previews & block screenshots';

  @override
  String get blockScreenshotsSubtitle =>
      'Covers app in recents and blocks screenshots on Android';

  @override
  String get webScreenshotNote =>
      'Screenshot protection is exclusive to the mobile app';

  @override
  String get quickHideHeading => 'Quick-Hide';

  @override
  String get quickHideExplanation =>
      'Tap the eye-off icon in the top header anytime to instantly conceal the screen. If a PIN is active, the app locks; otherwise, a peaceful cover appears until tapped.';

  @override
  String get testQuickHideButton => 'Test Quick-Hide Now';

  @override
  String get comingSoonHeading => 'Coming Soon';

  @override
  String get neutralRemindersTitle => 'Discreet Neutral Reminders';

  @override
  String get neutralRemindersSubtitle =>
      'Local reminders with gentle, private wording';

  @override
  String get exportDataTitle => 'Export My Data';

  @override
  String get exportDataSubtitle => 'Download a private copy of your records';

  @override
  String get deleteAccountTitle => 'Delete My Account';

  @override
  String get deleteAccountSubtitle =>
      'Permanently delete your account and all data';

  @override
  String get disableLockDialogTitle => 'Turn Off App Lock';

  @override
  String get disableLockDialogBody =>
      'Please enter your current PIN to turn off app lock.';

  @override
  String get currentPinLabel => 'Current PIN';

  @override
  String get pinCancel => 'Cancel';

  @override
  String get turnOffConfirm => 'Turn Off';

  @override
  String get pinIncorrect => 'Incorrect PIN';

  @override
  String get lockDisabledFeedback => 'App lock has been disabled.';

  @override
  String get autoLockTimeoutTitle => 'Auto-Lock Timeout';

  @override
  String get timeoutImmediately => 'Immediately';

  @override
  String get timeout30Seconds => '30 seconds (Default)';

  @override
  String get timeout1Minute => '1 minute';

  @override
  String get timeout5Minutes => '5 minutes';

  @override
  String get quickHideSemanticsLabel => 'Quick hide screen';

  @override
  String get cycleOptInTitle => 'CycleCare · Optional Body Rhythm';

  @override
  String get cycleOptInSubtitle =>
      'A private, voluntary space to notice your natural cycles.';

  @override
  String get cycleOptInNoticeHeader => 'Your privacy & how this works';

  @override
  String get cycleOptInNoticeStorage =>
      'What is stored: Dates and symptoms you choose to enter, kept on the BloomWell server under your account and visible only to you.';

  @override
  String get cycleOptInNoticeEstimates =>
      'Estimates are suggestions: Any future estimate is an approximation based strictly on your own logs. They can be wrong and vary naturally.';

  @override
  String get cycleOptInNoticeNonMedical =>
      'Not medical advice: BloomWell is a self-care wellness companion and never provides medical diagnoses or clinical guidance.';

  @override
  String get cycleOptInNoticeControl =>
      'Always your choice: Cycle tracking is completely optional. You can turn it off or permanently delete your cycle records at any time.';

  @override
  String get cycleOptInEnableButton => 'Turn on cycle tracking';

  @override
  String get cycleOptInNotNowButton => 'Not now';

  @override
  String get cycleCalendarHeader => 'Cycle Calendar';

  @override
  String get cycleCalendarPrevMonth => 'Previous month';

  @override
  String get cycleCalendarNextMonth => 'Next month';

  @override
  String get cycleLegendLogged => 'Logged period';

  @override
  String get cycleLegendEstimate => 'Estimated window';

  @override
  String get cycleLegendSymptoms => 'Symptoms logged';

  @override
  String get cycleDaySheetTitle => 'Day Details';

  @override
  String get cycleDayNoLogs => 'No period or symptoms logged for this day.';

  @override
  String get cycleDayPeriodLogged => 'Period logged';

  @override
  String get cycleDayEstimateWindow => 'Estimated window';

  @override
  String get cycleActionLogPeriod => 'Log period';

  @override
  String get cycleActionLogSymptom => 'Log symptom';

  @override
  String get cycleActionEditPeriod => 'Edit period';

  @override
  String get cycleActionDeletePeriod => 'Delete period';

  @override
  String get cycleDeletePeriodConfirm =>
      'Delete this period log? This action cannot be undone.';

  @override
  String get cycleQuickStartedToday => 'Period started today';

  @override
  String get cycleQuickEndedToday => 'Period ended today';

  @override
  String get cycleQuickPeriodEnded => 'Period ended';

  @override
  String get cycleSwitchToListView => 'Switch to accessible list view';

  @override
  String get cycleSwitchToGridView => 'Switch to calendar grid view';

  @override
  String get cycleLogPeriodTitle => 'Log Period';

  @override
  String get cycleEditPeriodTitle => 'Edit Period';

  @override
  String get cycleStartDateLabel => 'Start date';

  @override
  String get cycleEndDateLabel => 'End date (optional)';

  @override
  String get cycleSaveButton => 'Save';

  @override
  String get cycleSavingButton => 'Saving...';

  @override
  String get cycleCancelButton => 'Cancel';

  @override
  String get cyclePeriodSaved => 'Period logged successfully 🌸';

  @override
  String get cyclePeriodDeleted => 'Period record deleted.';

  @override
  String get cycleErrorFutureDate => 'Start date cannot be in the future.';

  @override
  String get cycleErrorInvalidRange =>
      'End date must be on or after the start date.';

  @override
  String get cycleErrorOverlap =>
      'This period overlaps with an already recorded period.';

  @override
  String get cycleLogSymptomTitle => 'Log Symptoms';

  @override
  String get cycleEditSymptomTitle => 'Edit Symptom';

  @override
  String get cycleSymptomDateLabel => 'Date';

  @override
  String get cycleSymptomTypeLabel => 'What are you noticing?';

  @override
  String get cycleSymptomCramps => 'Cramps';

  @override
  String get cycleSymptomBloating => 'Bloating';

  @override
  String get cycleSymptomFatigue => 'Fatigue';

  @override
  String get cycleSymptomHeadache => 'Headache';

  @override
  String get cycleSymptomBackPain => 'Back pain';

  @override
  String get cycleSymptomBreastTenderness => 'Breast tenderness';

  @override
  String get cycleSymptomNausea => 'Nausea';

  @override
  String get cycleSymptomMoodChanges => 'Mood changes';

  @override
  String get cycleSymptomAcne => 'Acne';

  @override
  String get cycleSymptomCravings => 'Cravings';

  @override
  String get cycleSymptomSleepTrouble => 'Sleep trouble';

  @override
  String get cycleSymptomOther => 'Other';

  @override
  String get cycleCustomLabelLabel => 'Custom symptom name';

  @override
  String get cycleCustomLabelPlaceholder => 'e.g. Lower pelvic ache';

  @override
  String cycleSeverityLabel(String label) {
    return 'Severity: $label';
  }

  @override
  String get cycleSeverity1 => 'Barely noticeable';

  @override
  String get cycleSeverity2 => 'Mild';

  @override
  String get cycleSeverity3 => 'Moderate';

  @override
  String get cycleSeverity4 => 'Strong';

  @override
  String get cycleSeverity5 => 'Very strong';

  @override
  String get cycleSeverityDisclaimer =>
      'If symptoms feel severe or worrying, talking to a doctor or nurse can help.';

  @override
  String get cycleNotesLabel => 'Notes (optional)';

  @override
  String get cycleNotesPlaceholder =>
      'How does this feel? Any gentle observations...';

  @override
  String cycleNotesCounter(int count) {
    return '$count / 500';
  }

  @override
  String get cycleSymptomSaved => 'Symptom logged successfully 🌸';

  @override
  String get cycleSymptomDeleted => 'Symptom record deleted.';

  @override
  String get cycleDeleteSymptomConfirm =>
      'Delete this symptom log? This action cannot be undone.';

  @override
  String get cycleEstimateTitle => 'Cycle Observation';

  @override
  String get cycleEstimateBadge => 'Estimate';

  @override
  String get cycleEstimateDisclaimer =>
      'This is an estimate and can be wrong. It is not medical advice.';

  @override
  String cycleEstimateNotEnoughData(int count) {
    return 'Log a few more periods to see an estimate ($count more needed).';
  }

  @override
  String get cycleEstimateTooVariable =>
      'Your logged cycles vary too much for a useful estimate.';

  @override
  String cycleEstimateRange(String rangeStart, String rangeEnd) {
    return 'Next period expected around $rangeStart to $rangeEnd.';
  }

  @override
  String cycleEstimateDetails(int days, int count) {
    return 'Typical length: $days days · Based on your last $count logged cycles.';
  }

  @override
  String get cycleHistoryTitle => 'Recorded Cycles';

  @override
  String get cycleHistoryEmpty =>
      'No cycles recorded yet. Your logged periods will appear here.';

  @override
  String cycleHistoryCycleLength(int days) {
    return '$days days';
  }

  @override
  String get cycleHistoryOngoing => 'Ongoing';

  @override
  String get cycleHistoryDelete => 'Delete';

  @override
  String get cycleHistoryEdit => 'Edit';

  @override
  String get cycleSettingsTitle => 'CycleCare Settings';

  @override
  String get cycleTurnOffTracking => 'Turn off cycle tracking';

  @override
  String get cycleTurnOffDialogTitle => 'Turn Off Cycle Tracking?';

  @override
  String get cycleTurnOffDialogBody =>
      'You can choose to keep your existing cycle records or delete them permanently from the server.';

  @override
  String get cycleKeepDataOption => 'Turn off and keep my data';

  @override
  String get cycleDeleteDataOption => 'Turn off and delete my cycle data';

  @override
  String get cycleDeleteConfirmTitle => 'Confirm Permanent Deletion';

  @override
  String get cycleDeleteConfirmBody =>
      'This will permanently delete all your logged periods and cycle symptoms from the server. This action cannot be undone.';

  @override
  String get cycleConfirmDeleteButton => 'Delete All Cycle Data';

  @override
  String get cycleTrackingDisabledFeedback =>
      'Cycle tracking has been turned off.';

  @override
  String get cycleTrackingDeletedFeedback =>
      'Cycle tracking turned off and all data deleted.';

  @override
  String get homeCycleCardTitle => 'Check in with your body';

  @override
  String get homeCycleCardSubtitle => 'Notice your energy and rhythm today';

  @override
  String get homeCycleCardAction => 'Open CycleCare';

  @override
  String get cycleDisabledNotice =>
      'Cycle tracking is currently off. Turn it on anytime to start logging.';

  @override
  String get selfCareStudioTitle => 'Self-Care Studio';

  @override
  String get selfCareStudioSubtitle =>
      'Curated gentle practices for body, mind, and study breaks.';

  @override
  String get selfCareCategoryAll => 'All';

  @override
  String get selfCareCategoryBreathing => 'Breathing';

  @override
  String get selfCareCategoryGrounding => 'Grounding';

  @override
  String get selfCareCategoryRelaxation => 'Relaxation';

  @override
  String get selfCareCategoryMovement => 'Movement';

  @override
  String get selfCareCategoryJournaling => 'Journaling';

  @override
  String get selfCareCategoryStudyBreak => 'Study Break';

  @override
  String get selfCareCategoryComfort => 'Comfort';

  @override
  String get selfCareCategoryConfidence => 'Confidence';

  @override
  String get selfCareDurationAny => 'Any duration';

  @override
  String get selfCareDuration2 => 'Up to 2 min';

  @override
  String get selfCareDuration5 => 'Up to 5 min';

  @override
  String get selfCareDuration10 => 'Up to 10 min';

  @override
  String get selfCareEmptyTitle => 'No activities match this filter';

  @override
  String get selfCareEmptySubtitle =>
      'Try choosing a different category or longer duration.';

  @override
  String get selfCareErrorTitle => 'Unable to load studio activities';

  @override
  String get selfCareRetry => 'Try again';

  @override
  String get selfCareHistoryButton => 'My activity history';

  @override
  String get selfCareRoutinesButton => 'Routines';

  @override
  String get selfCareOpenStudioButton => 'Open Studio';

  @override
  String get selfCareAddFavoriteA11y => 'Add to favorites';

  @override
  String get selfCareRemoveFavoriteA11y => 'Remove from favorites';

  @override
  String selfCareDurationMinutes(int count) {
    return '$count min';
  }

  @override
  String get activityDetailTitle => 'Activity Details';

  @override
  String get activityStartButton => 'Start gentle guide';

  @override
  String get activitySourceLabel => 'Source';

  @override
  String get activityStepsTitle => 'Guided Steps';

  @override
  String get activityComfortDoctorNote =>
      'If symptoms feel severe, unusual or last a long time, talking to a doctor or nurse can help.';

  @override
  String activityStepCounter(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get activityStepNext => 'Next';

  @override
  String get activityStepBack => 'Back';

  @override
  String get activityStepDone => 'Done';

  @override
  String get activityRatingTitle => 'Did this help?';

  @override
  String get activityRatingSubtitle =>
      'Optional feedback to help suggest gentler activities for you.';

  @override
  String get activityRatingSkip => 'Skip';

  @override
  String get activitySavedConfirmed => 'Activity completed and logged gently.';

  @override
  String get activityHistoryTitle => 'My Activity History';

  @override
  String get activityHistorySubtitle =>
      'A quiet record of your gentle moments.';

  @override
  String get activityHistoryEmpty =>
      'No completed activities yet. Take your time.';

  @override
  String get comfortModeTitle => 'A gentle moment';

  @override
  String get comfortModeSubtitle =>
      'No pressure. Pick what feels okay right now.';

  @override
  String get comfortNeedQuestion => 'What do you need?';

  @override
  String get comfortNeedQuickBreak => 'A quick break';

  @override
  String get comfortNeedCalmDown => 'Calm down';

  @override
  String get comfortNeedBodyComfort => 'Body comfort';

  @override
  String get comfortNeedFocus => 'Focus';

  @override
  String get comfortReasonFavorite => 'One of your favorites';

  @override
  String get comfortReasonNewForYou => 'Something new to try';

  @override
  String get comfortReasonQuick => 'Gentle and quick';

  @override
  String get comfortReasonOther => 'Suggested for you';

  @override
  String get comfortShowSomethingElse => 'Show me something else';

  @override
  String get comfortPlanTitle => 'My comfort plan';

  @override
  String get comfortPlanSubtitle =>
      'Your saved soothing practices for difficult days.';

  @override
  String get comfortPlanEmpty =>
      'No practices in your plan yet. Save a few favorites here for easy access.';

  @override
  String get comfortAddToPlan => 'Add to comfort plan';

  @override
  String get comfortRemoveFromPlan => 'Remove from plan';

  @override
  String get comfortFindSupport => 'Find support';

  @override
  String get comfortNonMedicalNotice =>
      'BloomWell is not a medical or emergency service. If you are going through a difficult time, reaching out to a trusted person or health professional can help.';

  @override
  String get routinesTitle => 'Routines';

  @override
  String get routinesSubtitle =>
      'Gentle rituals to nourish your rhythm without pressure.';

  @override
  String get routinesEmptyTitle => 'No routines created yet';

  @override
  String get routinesEmptySubtitle =>
      'Create a soothing daily or weekly routine that feels good to you.';

  @override
  String get routinesNewButton => 'New routine';

  @override
  String get routinesCreateTitle => 'Create Routine';

  @override
  String get routinesEditTitle => 'Edit Routine';

  @override
  String get routinesTitleField => 'Routine Title';

  @override
  String get routinesStartDateField => 'Start Date (optional)';

  @override
  String get routinesEndDateField => 'End Date (optional)';

  @override
  String get routinesSaveButton => 'Save Routine';

  @override
  String get routinesDeleteButton => 'Delete';

  @override
  String get routinesDeleteConfirm =>
      'Are you sure you want to delete this routine?';

  @override
  String get routinesAddItem => 'Add activity';

  @override
  String get routinesLimitExceeded =>
      'You have reached the maximum limit of 20 routines.';

  @override
  String get routinesItemLimitExceeded =>
      'You have reached the maximum limit of 50 activities for this routine.';

  @override
  String routinesProgressText(int completed, int total) {
    return '$completed of $total done';
  }

  @override
  String get examsTitle => 'Exams & Deadlines';

  @override
  String get examsSubtitle =>
      'Keep track of academic events so study suggestions can feel gentler.';

  @override
  String get examsPlannerNotice =>
      'Adding exams and deadlines lets BloomWell suggest gentler study plans later. This is optional.';

  @override
  String get examsPlannerComingSoon => 'Study planner coming soon';

  @override
  String get examsTabUpcoming => 'Upcoming';

  @override
  String get examsTabPast => 'Past';

  @override
  String get examsNewButton => 'Add deadline or exam';

  @override
  String get examsCreateTitle => 'Add Academic Event';

  @override
  String get examsEditTitle => 'Edit Academic Event';

  @override
  String get examsTitleLabel => 'Title (max 80 chars)';

  @override
  String get examsDateLabel => 'Event Date';

  @override
  String get examsTypeLabel => 'Event Type';

  @override
  String get examsTypeExam => 'Exam';

  @override
  String get examsTypeAssignment => 'Assignment';

  @override
  String get examsTypePresentation => 'Presentation';

  @override
  String get examsTypeOther => 'Other';

  @override
  String get examsSaveButton => 'Save Event';

  @override
  String get examsDeleteButton => 'Delete';

  @override
  String get examsDeleteConfirm =>
      'Are you sure you want to delete this event?';

  @override
  String get examsEmptyUpcoming =>
      'No upcoming exams or deadlines entered. Enjoy your free rhythm.';

  @override
  String get examsEmptyPast => 'No past exams recorded.';

  @override
  String examsInDays(int days) {
    return 'in $days days';
  }

  @override
  String get examsInOneDay => 'tomorrow';

  @override
  String get examsToday => 'today';

  @override
  String examsDaysAgo(int days) {
    return '$days days ago';
  }
}
