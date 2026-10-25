import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'BloomWell'**
  String get appName;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hey, lovely! 🌷'**
  String get homeGreeting;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Take a little moment for yourself.'**
  String get homeSubtitle;

  /// No description provided for @discreetBadge.
  ///
  /// In en, this message translates to:
  /// **'Discreet'**
  String get discreetBadge;

  /// No description provided for @discreetSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Discreet Mode (Planned)'**
  String get discreetSheetTitle;

  /// No description provided for @discreetSheetBody.
  ///
  /// In en, this message translates to:
  /// **'BloomWell is designed with privacy as a foundation. In a future update, you will be able to lock the app with PIN or biometrics, obscure switcher previews, and configure neutral notifications. Currently, this mode is planned and not yet active.'**
  String get discreetSheetBody;

  /// No description provided for @discreetSheetButton.
  ///
  /// In en, this message translates to:
  /// **'Got it 🌸'**
  String get discreetSheetButton;

  /// No description provided for @moodQuestion.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling right now?'**
  String get moodQuestion;

  /// No description provided for @moodReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get moodReset;

  /// No description provided for @moodHappy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get moodHappy;

  /// No description provided for @moodCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get moodCalm;

  /// No description provided for @moodOkay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get moodOkay;

  /// No description provided for @moodSad.
  ///
  /// In en, this message translates to:
  /// **'Sad'**
  String get moodSad;

  /// No description provided for @moodStressed.
  ///
  /// In en, this message translates to:
  /// **'Stressed'**
  String get moodStressed;

  /// No description provided for @moodHappyAffirmation.
  ///
  /// In en, this message translates to:
  /// **'So glad you\'re feeling radiant today! Let this light nourish your day. ✨'**
  String get moodHappyAffirmation;

  /// No description provided for @moodCalmAffirmation.
  ///
  /// In en, this message translates to:
  /// **'Cherish this peaceful energy. May your day stay gentle and unhurried. 🌿'**
  String get moodCalmAffirmation;

  /// No description provided for @moodOkayAffirmation.
  ///
  /// In en, this message translates to:
  /// **'Steady and okay is wonderful. Honor wherever you are today. ☁️'**
  String get moodOkayAffirmation;

  /// No description provided for @moodSadAffirmation.
  ///
  /// In en, this message translates to:
  /// **'It is okay to be gentle and slow today, darling. Sending warm thoughts. 🤍'**
  String get moodSadAffirmation;

  /// No description provided for @moodStressedAffirmation.
  ///
  /// In en, this message translates to:
  /// **'Take a slow, deep breath. You are capable and more than your worries. 💜'**
  String get moodStressedAffirmation;

  /// No description provided for @moodDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Session check-in · Not persisted'**
  String get moodDisclaimer;

  /// No description provided for @moodSupportiveMessage.
  ///
  /// In en, this message translates to:
  /// **'It looks like today might be a bit heavy. You don\'t have to carry it alone. Please be extra gentle with yourself.'**
  String get moodSupportiveMessage;

  /// No description provided for @tryComfortMode.
  ///
  /// In en, this message translates to:
  /// **'Try Comfort Mode'**
  String get tryComfortMode;

  /// No description provided for @findSupport.
  ///
  /// In en, this message translates to:
  /// **'Find support'**
  String get findSupport;

  /// No description provided for @dailyEncouragementBadge.
  ///
  /// In en, this message translates to:
  /// **'Daily Bloom Thought'**
  String get dailyEncouragementBadge;

  /// No description provided for @dailyEncouragementQuote.
  ///
  /// In en, this message translates to:
  /// **'\"Give yourself credit for how far you\'ve come. Soft days and slow progress still count. You don\'t have to carry the whole world today.\"'**
  String get dailyEncouragementQuote;

  /// No description provided for @dailyEncouragementTip.
  ///
  /// In en, this message translates to:
  /// **'Remember to take a sip of water and rest your shoulders.'**
  String get dailyEncouragementTip;

  /// No description provided for @bookmarkSessionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Bookmark for this session'**
  String get bookmarkSessionTooltip;

  /// No description provided for @bookmarkedFeedback.
  ///
  /// In en, this message translates to:
  /// **'Thought bookmarked for this session 💖'**
  String get bookmarkedFeedback;

  /// No description provided for @unbookmarkedFeedback.
  ///
  /// In en, this message translates to:
  /// **'Removed bookmark'**
  String get unbookmarkedFeedback;

  /// No description provided for @planStudyWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan my study week 📚'**
  String get planStudyWeekTitle;

  /// No description provided for @planStudyWeekSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cycle-aware, exam-aware suggestions to pace your study and rest.'**
  String get planStudyWeekSubtitle;

  /// No description provided for @hardDayButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'I\'m having a hard day 🤍'**
  String get hardDayButtonLabel;

  /// No description provided for @comingSoonBadge.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoonBadge;

  /// No description provided for @selfCareHeading.
  ///
  /// In en, this message translates to:
  /// **'Self-Care Routines 🌿'**
  String get selfCareHeading;

  /// No description provided for @selfCareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gentle rituals to nourish your body and mind'**
  String get selfCareSubtitle;

  /// No description provided for @journalTitle.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journalTitle;

  /// No description provided for @journalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Private thoughts & feelings'**
  String get journalSubtitle;

  /// No description provided for @journalBadge.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get journalBadge;

  /// No description provided for @cycleCareTitle.
  ///
  /// In en, this message translates to:
  /// **'CycleCare'**
  String get cycleCareTitle;

  /// No description provided for @cycleCareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Symptom & cycle tracking'**
  String get cycleCareSubtitle;

  /// No description provided for @cycleCareBadge.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get cycleCareBadge;

  /// No description provided for @breatheTitle.
  ///
  /// In en, this message translates to:
  /// **'Breathe & Relax'**
  String get breatheTitle;

  /// No description provided for @breatheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guided grounding exercises'**
  String get breatheSubtitle;

  /// No description provided for @breatheBadge.
  ///
  /// In en, this message translates to:
  /// **'about 2 min'**
  String get breatheBadge;

  /// No description provided for @bloomBuddyTitle.
  ///
  /// In en, this message translates to:
  /// **'Bloom Buddy'**
  String get bloomBuddyTitle;

  /// No description provided for @bloomBuddySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gentle companion'**
  String get bloomBuddySubtitle;

  /// No description provided for @breathingCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Mindful Breathing'**
  String get breathingCardTitle;

  /// No description provided for @breathingCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Inhale peace, exhale tension'**
  String get breathingCardSubtitle;

  /// No description provided for @breathingDurationBadge.
  ///
  /// In en, this message translates to:
  /// **'about 2 min'**
  String get breathingDurationBadge;

  /// No description provided for @breathingCycleCount.
  ///
  /// In en, this message translates to:
  /// **'Cycle {current} of {total}'**
  String breathingCycleCount(int current, int total);

  /// No description provided for @breathingPhaseIdleTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to relax'**
  String get breathingPhaseIdleTitle;

  /// No description provided for @breathingPhaseIdleInstruction.
  ///
  /// In en, this message translates to:
  /// **'Take a comfortable breath when you are ready'**
  String get breathingPhaseIdleInstruction;

  /// No description provided for @breathingPhaseInhaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Breathe In'**
  String get breathingPhaseInhaleTitle;

  /// No description provided for @breathingPhaseInhaleInstruction.
  ///
  /// In en, this message translates to:
  /// **'Inhale peace and clarity...'**
  String get breathingPhaseInhaleInstruction;

  /// No description provided for @breathingPhaseHoldInTitle.
  ///
  /// In en, this message translates to:
  /// **'Hold Gently'**
  String get breathingPhaseHoldInTitle;

  /// No description provided for @breathingPhaseHoldInInstruction.
  ///
  /// In en, this message translates to:
  /// **'Hold your breath softly...'**
  String get breathingPhaseHoldInInstruction;

  /// No description provided for @breathingPhaseExhaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Breathe Out'**
  String get breathingPhaseExhaleTitle;

  /// No description provided for @breathingPhaseExhaleInstruction.
  ///
  /// In en, this message translates to:
  /// **'Release all tightness and worries...'**
  String get breathingPhaseExhaleInstruction;

  /// No description provided for @breathingPhaseHoldOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get breathingPhaseHoldOutTitle;

  /// No description provided for @breathingPhaseHoldOutInstruction.
  ///
  /// In en, this message translates to:
  /// **'Rest in this gentle stillness...'**
  String get breathingPhaseHoldOutInstruction;

  /// No description provided for @breathingStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start Quick Session'**
  String get breathingStartButton;

  /// No description provided for @breathingPauseButton.
  ///
  /// In en, this message translates to:
  /// **'Pause Exercise'**
  String get breathingPauseButton;

  /// No description provided for @footerMotifs.
  ///
  /// In en, this message translates to:
  /// **'🌸 · ☁️ · 🤍 · 🌙 · ✨'**
  String get footerMotifs;

  /// No description provided for @footerTagline.
  ///
  /// In en, this message translates to:
  /// **'BloomWell · Gentle, private self-care'**
  String get footerTagline;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMood.
  ///
  /// In en, this message translates to:
  /// **'My Mood'**
  String get navMood;

  /// No description provided for @navCycleCare.
  ///
  /// In en, this message translates to:
  /// **'CycleCare'**
  String get navCycleCare;

  /// No description provided for @navBloomBuddy.
  ///
  /// In en, this message translates to:
  /// **'Bloom Buddy'**
  String get navBloomBuddy;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @placeholderPlannedLabel.
  ///
  /// In en, this message translates to:
  /// **'Coming in a later update'**
  String get placeholderPlannedLabel;

  /// No description provided for @placeholderBackToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get placeholderBackToHome;

  /// No description provided for @placeholderPlannedHeading.
  ///
  /// In en, this message translates to:
  /// **'Planned Implementation'**
  String get placeholderPlannedHeading;

  /// No description provided for @placeholderDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'BloomWell does not fabricate user records or mock health data. Real tracking begins when the local storage & API layers are integrated.'**
  String get placeholderDisclaimer;

  /// No description provided for @moodPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'MoodMap & Insights'**
  String get moodPlaceholderTitle;

  /// No description provided for @moodPlaceholderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Understand your emotional patterns over time'**
  String get moodPlaceholderSubtitle;

  /// No description provided for @moodPlaceholderDescription.
  ///
  /// In en, this message translates to:
  /// **'MoodMap will provide historical charts, weekly reflections, and energy observations based on your daily check-ins. Today, you can try out the interactive mood selector directly on the Home screen.'**
  String get moodPlaceholderDescription;

  /// No description provided for @cycleCarePlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'CycleCare'**
  String get cycleCarePlaceholderTitle;

  /// No description provided for @cycleCarePlaceholderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gentle, private menstrual and symptom logging'**
  String get cycleCarePlaceholderSubtitle;

  /// No description provided for @cycleCarePlaceholderDescription.
  ///
  /// In en, this message translates to:
  /// **'CycleCare will allow you to log period dates, cramp severity, bloating, and fatigue. All cycle estimates will be clearly distinguished from recorded dates, strictly non-diagnostic, and stored securely.'**
  String get cycleCarePlaceholderDescription;

  /// No description provided for @bloomBuddyPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Bloom Buddy'**
  String get bloomBuddyPlaceholderTitle;

  /// No description provided for @bloomBuddyPlaceholderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your warm, consent-separated companion'**
  String get bloomBuddyPlaceholderSubtitle;

  /// No description provided for @bloomBuddyPlaceholderDescription.
  ///
  /// In en, this message translates to:
  /// **'Bloom Buddy will bring together mindful reflections and peer care. Planned sections arriving in future updates include: AI Companion (with explicit consent), I\'m Here (gentle listening), Cycle Circles (moderated topic peer support), and HelpHub (verified campus access points).'**
  String get bloomBuddyPlaceholderDescription;

  /// No description provided for @profilePlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile & Privacy Center'**
  String get profilePlaceholderTitle;

  /// No description provided for @profilePlaceholderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete control over your personal data'**
  String get profilePlaceholderSubtitle;

  /// No description provided for @profilePlaceholderDescription.
  ///
  /// In en, this message translates to:
  /// **'The Privacy Center will host Discreet Mode (app lock, neutral notifications), exportable Doctor-visit summaries, language selection (English, Hindi, Marathi), and full one-tap data deletion.'**
  String get profilePlaceholderDescription;

  /// No description provided for @journalPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Private Journal'**
  String get journalPlaceholderTitle;

  /// No description provided for @journalPlaceholderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A safe, judgment-free space to write'**
  String get journalPlaceholderSubtitle;

  /// No description provided for @journalPlaceholderDescription.
  ///
  /// In en, this message translates to:
  /// **'Your journal entries will be encrypted, private by default, and never browsable by moderators or administrators. An on-device safety layer ensures gentle resources appear if distress language is detected.'**
  String get journalPlaceholderDescription;

  /// No description provided for @breathePlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Breathe & Relax'**
  String get breathePlaceholderTitle;

  /// No description provided for @breathePlaceholderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gentle somatic calming & grounding exercises'**
  String get breathePlaceholderSubtitle;

  /// No description provided for @breathePlaceholderDescription.
  ///
  /// In en, this message translates to:
  /// **'Expanded audio sessions, 4-7-8 breathing techniques, progressive muscle relaxation, and warm compress reminders will be available here. For now, try out the mindful breathing exercise right on your Home screen!'**
  String get breathePlaceholderDescription;

  /// No description provided for @comfortPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Comfort Mode'**
  String get comfortPlaceholderTitle;

  /// No description provided for @comfortPlaceholderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gentle care for difficult days'**
  String get comfortPlaceholderSubtitle;

  /// No description provided for @comfortPlaceholderDescription.
  ///
  /// In en, this message translates to:
  /// **'Comfort Mode offers simplified, soothing routines, warm compress reminders, calming soundscapes, and non-diagnostic grounding prompts for when you are not feeling your best.'**
  String get comfortPlaceholderDescription;

  /// No description provided for @studyPlannerPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Study Planner'**
  String get studyPlannerPlaceholderTitle;

  /// No description provided for @studyPlannerPlaceholderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cycle-aware, exam-aware academic pacing'**
  String get studyPlannerPlaceholderSubtitle;

  /// No description provided for @studyPlannerPlaceholderDescription.
  ///
  /// In en, this message translates to:
  /// **'The Study Planner suggests lighter or heavier study blocks and rest breaks around your own energy check-ins and entered exam dates — as gentle suggestions, never rigid predictions.'**
  String get studyPlannerPlaceholderDescription;

  /// No description provided for @helpPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Support Resources & HelpHub'**
  String get helpPlaceholderTitle;

  /// No description provided for @helpPlaceholderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verified campus care and period-product access'**
  String get helpPlaceholderSubtitle;

  /// No description provided for @helpPlaceholderDescription.
  ///
  /// In en, this message translates to:
  /// **'HelpHub connects you to verified campus dispensers, health center resources, helplines, and period-product access points with real verification dates and student reporting.'**
  String get helpPlaceholderDescription;

  /// No description provided for @avatarInitials.
  ///
  /// In en, this message translates to:
  /// **'BW'**
  String get avatarInitials;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You are all caught up! No new notifications right now. 🌸'**
  String get notificationsEmpty;

  /// No description provided for @notificationsClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get notificationsClose;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get filterCalm;

  /// No description provided for @filterEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get filterEnergy;

  /// No description provided for @filterSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get filterSleep;

  /// No description provided for @filterFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get filterFocus;

  /// No description provided for @filterMovement.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get filterMovement;

  /// No description provided for @featuredHeading.
  ///
  /// In en, this message translates to:
  /// **'Featured for You'**
  String get featuredHeading;

  /// No description provided for @featuredBreathingTitle.
  ///
  /// In en, this message translates to:
  /// **'Deep Breathing'**
  String get featuredBreathingTitle;

  /// No description provided for @featuredBreathingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'2 min soothing rhythm'**
  String get featuredBreathingSubtitle;

  /// No description provided for @featuredBodyScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Body Scan & Unwind'**
  String get featuredBodyScanTitle;

  /// No description provided for @featuredBodyScanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'5 min gentle tension release'**
  String get featuredBodyScanSubtitle;

  /// No description provided for @featuredJournalTitle.
  ///
  /// In en, this message translates to:
  /// **'Mindful Journal'**
  String get featuredJournalTitle;

  /// No description provided for @featuredJournalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Express your thoughts safely'**
  String get featuredJournalSubtitle;

  /// No description provided for @featuredStretchTitle.
  ///
  /// In en, this message translates to:
  /// **'Gentle Stretch'**
  String get featuredStretchTitle;

  /// No description provided for @featuredStretchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Release back and neck tension'**
  String get featuredStretchSubtitle;

  /// No description provided for @featuredSleepTitle.
  ///
  /// In en, this message translates to:
  /// **'Nighttime Wind Down'**
  String get featuredSleepTitle;

  /// No description provided for @featuredSleepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Soft soothing sleep sounds'**
  String get featuredSleepSubtitle;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Little Reminder'**
  String get reminderTitle;

  /// No description provided for @reminderBody.
  ///
  /// In en, this message translates to:
  /// **'Drink a glass of water and take a deep breath. You are doing great today.'**
  String get reminderBody;

  /// No description provided for @cyclePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Cycle & Body Rhythm'**
  String get cyclePreviewTitle;

  /// No description provided for @cyclePreviewBadge.
  ///
  /// In en, this message translates to:
  /// **'Educational'**
  String get cyclePreviewBadge;

  /// No description provided for @cyclePreviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Understand your natural flow'**
  String get cyclePreviewSubtitle;

  /// No description provided for @cyclePreviewTip.
  ///
  /// In en, this message translates to:
  /// **'Today\'s gentle tip: Stay hydrated and rest when your body asks.'**
  String get cyclePreviewTip;

  /// No description provided for @cyclePreviewDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Cycle insights are personal suggestions and never medical diagnoses.'**
  String get cyclePreviewDisclaimer;

  /// No description provided for @breatheScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Mindful Breathing'**
  String get breatheScreenTitle;

  /// No description provided for @breatheScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'8 soothing cycles · ~2 min'**
  String get breatheScreenSubtitle;

  /// No description provided for @breatheRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s remaining'**
  String breatheRemainingLabel(int seconds);

  /// No description provided for @breathePhaseInhale.
  ///
  /// In en, this message translates to:
  /// **'Breathe In'**
  String get breathePhaseInhale;

  /// No description provided for @breathePhaseHold.
  ///
  /// In en, this message translates to:
  /// **'Hold Softly'**
  String get breathePhaseHold;

  /// No description provided for @breathePhaseExhale.
  ///
  /// In en, this message translates to:
  /// **'Breathe Out'**
  String get breathePhaseExhale;

  /// No description provided for @breathePhaseRest.
  ///
  /// In en, this message translates to:
  /// **'Rest & Center'**
  String get breathePhaseRest;

  /// No description provided for @breathePlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get breathePlay;

  /// No description provided for @breathePause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get breathePause;

  /// No description provided for @breatheFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get breatheFinish;

  /// No description provided for @breatheCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Session Complete 🌸'**
  String get breatheCompletedTitle;

  /// No description provided for @breatheCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Wonderful job taking this peaceful moment for your mind and body.'**
  String get breatheCompletedMessage;

  /// No description provided for @breatheReturnHome.
  ///
  /// In en, this message translates to:
  /// **'Return to Home'**
  String get breatheReturnHome;

  /// No description provided for @breatheRestart.
  ///
  /// In en, this message translates to:
  /// **'Breathe Again'**
  String get breatheRestart;

  /// No description provided for @breatheNonDiagnosticNote.
  ///
  /// In en, this message translates to:
  /// **'Non-diagnostic relaxation exercise. Stop anytime if you feel lightheaded.'**
  String get breatheNonDiagnosticNote;

  /// No description provided for @myMoodTitle.
  ///
  /// In en, this message translates to:
  /// **'My Mood'**
  String get myMoodTitle;

  /// No description provided for @myMoodEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Check in with your feelings'**
  String get myMoodEmptyTitle;

  /// No description provided for @myMoodEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notice how your body and emotions feel today. Your reflections are private and never leave your phone.'**
  String get myMoodEmptySubtitle;

  /// No description provided for @myMoodCheckInButton.
  ///
  /// In en, this message translates to:
  /// **'Check In on Home'**
  String get myMoodCheckInButton;

  /// No description provided for @myMoodPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Strictly on-device · No tracking'**
  String get myMoodPrivacyNote;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to BloomWell'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A gentle, private wellness companion made for students.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeFeature1Title.
  ///
  /// In en, this message translates to:
  /// **'Privacy First'**
  String get welcomeFeature1Title;

  /// No description provided for @welcomeFeature1Desc.
  ///
  /// In en, this message translates to:
  /// **'Your journal, mood, and cycle reflections are private and owner-scoped.'**
  String get welcomeFeature1Desc;

  /// No description provided for @welcomeFeature2Title.
  ///
  /// In en, this message translates to:
  /// **'Calm & Supportive'**
  String get welcomeFeature2Title;

  /// No description provided for @welcomeFeature2Desc.
  ///
  /// In en, this message translates to:
  /// **'Gentle pacing, mindful breathing, and non-judgmental comfort.'**
  String get welcomeFeature2Desc;

  /// No description provided for @welcomeFeature3Title.
  ///
  /// In en, this message translates to:
  /// **'Academic Pacing'**
  String get welcomeFeature3Title;

  /// No description provided for @welcomeFeature3Desc.
  ///
  /// In en, this message translates to:
  /// **'Cycle-aware, exam-aware suggestions to pace study and rest.'**
  String get welcomeFeature3Desc;

  /// No description provided for @welcomeCta.
  ///
  /// In en, this message translates to:
  /// **'Explore BloomWell'**
  String get welcomeCta;

  /// No description provided for @debugPreviewWelcome.
  ///
  /// In en, this message translates to:
  /// **'Preview Welcome Screen (Debug)'**
  String get debugPreviewWelcome;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignIn;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authCreateAccount;

  /// No description provided for @authRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegister;

  /// No description provided for @authLogin.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get authLogin;

  /// No description provided for @authLogout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get authLogout;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get authEmail;

  /// No description provided for @authEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'you@campus.edu'**
  String get authEmailPlaceholder;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'At least 10 characters'**
  String get authPasswordPlaceholder;

  /// No description provided for @authPasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authPasswordConfirm;

  /// No description provided for @authPasswordConfirmPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get authPasswordConfirmPlaceholder;

  /// No description provided for @authDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name (optional)'**
  String get authDisplayName;

  /// No description provided for @authDisplayNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get authDisplayNamePlaceholder;

  /// No description provided for @authTimezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get authTimezone;

  /// No description provided for @authLoginPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get authLoginPrompt;

  /// No description provided for @authRegisterPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Create one'**
  String get authRegisterPrompt;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to access your gentle self-care space.'**
  String get authLoginSubtitle;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Join BloomWell'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A private, supportive wellness sanctuary designed for students.'**
  String get authRegisterSubtitle;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 10 characters'**
  String get authPasswordMinLength;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordMismatch;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get authEmailInvalid;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get authEmailRequired;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get authPasswordRequired;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password. Please check your credentials.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorEmailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'An account with this email address already exists.'**
  String get authErrorEmailAlreadyRegistered;

  /// No description provided for @authErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait {seconds} seconds before trying again.'**
  String authErrorRateLimited(int seconds);

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please check your connection and try again.'**
  String get authErrorGeneric;

  /// No description provided for @authLoggingIn.
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get authLoggingIn;

  /// No description provided for @authRegistering.
  ///
  /// In en, this message translates to:
  /// **'Creating your account...'**
  String get authRegistering;

  /// No description provided for @authLoggingOut.
  ///
  /// In en, this message translates to:
  /// **'Logging out...'**
  String get authLoggingOut;

  /// No description provided for @authLogoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get authLogoutConfirmation;

  /// No description provided for @authLogoutCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get authLogoutCancel;

  /// No description provided for @authLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get authLogoutConfirm;

  /// No description provided for @discreetOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep Your Space Discreet 🌸'**
  String get discreetOnboardingTitle;

  /// No description provided for @discreetOnboardingBody.
  ///
  /// In en, this message translates to:
  /// **'Many students share devices or live with roommates. You can add a quick PIN lock to shield your check-ins and journal notes from casual view.'**
  String get discreetOnboardingBody;

  /// No description provided for @discreetOnboardingSetupButton.
  ///
  /// In en, this message translates to:
  /// **'Set Up PIN Lock'**
  String get discreetOnboardingSetupButton;

  /// No description provided for @discreetOnboardingNotNowButton.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get discreetOnboardingNotNowButton;

  /// No description provided for @pinTooShortMessage.
  ///
  /// In en, this message translates to:
  /// **'PIN must be 4 to 6 digits'**
  String get pinTooShortMessage;

  /// No description provided for @pinWeakMessage.
  ///
  /// In en, this message translates to:
  /// **'Please choose a stronger PIN (avoid 1234, 0000, or repeated digits)'**
  String get pinWeakMessage;

  /// No description provided for @pinMismatchMessage.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match. Try again'**
  String get pinMismatchMessage;

  /// No description provided for @pinSetupSuccess.
  ///
  /// In en, this message translates to:
  /// **'App lock PIN set successfully 🌸'**
  String get pinSetupSuccess;

  /// No description provided for @pinConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Your PIN'**
  String get pinConfirmTitle;

  /// No description provided for @pinCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Up App Lock PIN'**
  String get pinCreateTitle;

  /// No description provided for @pinConfirmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your 4 to 6 digit PIN to confirm.'**
  String get pinConfirmSubtitle;

  /// No description provided for @pinCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a 4 to 6 digit convenience PIN to shield your space.'**
  String get pinCreateSubtitle;

  /// No description provided for @pinSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save PIN'**
  String get pinSaveButton;

  /// No description provided for @pinContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get pinContinueButton;

  /// No description provided for @appLockTitle.
  ///
  /// In en, this message translates to:
  /// **'BloomWell Locked'**
  String get appLockTitle;

  /// No description provided for @appLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to resume your gentle space.'**
  String get appLockSubtitle;

  /// No description provided for @lockoutActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Try again in {seconds} seconds.'**
  String lockoutActiveMessage(int seconds);

  /// No description provided for @pinIncorrectAttempts.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. ({attempts} failed attempts)'**
  String pinIncorrectAttempts(int attempts);

  /// No description provided for @biometricUnlockPrompt.
  ///
  /// In en, this message translates to:
  /// **'Unlock BloomWell to access your private space'**
  String get biometricUnlockPrompt;

  /// No description provided for @forgotPinDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get forgotPinDialogTitle;

  /// No description provided for @forgotPinDialogBody.
  ///
  /// In en, this message translates to:
  /// **'There is no server-side PIN recovery. To reset your PIN, you must log out. This will clear the PIN on this device and your local session. You can then log back in with your account password.'**
  String get forgotPinDialogBody;

  /// No description provided for @forgotPinCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get forgotPinCancel;

  /// No description provided for @forgotPinLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Log Out & Reset'**
  String get forgotPinLogoutConfirm;

  /// No description provided for @biometricsButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Unlock with biometrics'**
  String get biometricsButtonTooltip;

  /// No description provided for @unlockButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockButtonLabel;

  /// No description provided for @forgotPinButton.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get forgotPinButton;

  /// No description provided for @privacyCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Center'**
  String get privacyCenterTitle;

  /// No description provided for @privacyHonestyTitle.
  ///
  /// In en, this message translates to:
  /// **'How App Lock Works'**
  String get privacyHonestyTitle;

  /// No description provided for @privacyHonestyBody.
  ///
  /// In en, this message translates to:
  /// **'This PIN is a convenience lock against casual access (like a roommate borrowing your phone). It does NOT encrypt device data. BloomWell records are stored safely on the BloomWell server under your account and are visible only to you.'**
  String get privacyHonestyBody;

  /// No description provided for @appLockSectionHeading.
  ///
  /// In en, this message translates to:
  /// **'App Lock & PIN'**
  String get appLockSectionHeading;

  /// No description provided for @enableAppLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable App Lock'**
  String get enableAppLockTitle;

  /// No description provided for @appLockActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'PIN configured and active'**
  String get appLockActiveSubtitle;

  /// No description provided for @appLockInactiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require PIN to open BloomWell'**
  String get appLockInactiveSubtitle;

  /// No description provided for @changePinTitle.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePinTitle;

  /// No description provided for @biometricsToggleTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Biometrics'**
  String get biometricsToggleTitle;

  /// No description provided for @biometricsToggleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or Face ID as quick fallback'**
  String get biometricsToggleSubtitle;

  /// No description provided for @biometricsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometrics not available or not enrolled on this device.'**
  String get biometricsUnavailable;

  /// No description provided for @webBiometricsNote.
  ///
  /// In en, this message translates to:
  /// **'Biometrics unavailable on web'**
  String get webBiometricsNote;

  /// No description provided for @autoLockTimeoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Auto-lock timeout'**
  String get autoLockTimeoutLabel;

  /// No description provided for @screenPrivacyHeading.
  ///
  /// In en, this message translates to:
  /// **'Screen Privacy'**
  String get screenPrivacyHeading;

  /// No description provided for @blockScreenshotsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide previews & block screenshots'**
  String get blockScreenshotsTitle;

  /// No description provided for @blockScreenshotsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Covers app in recents and blocks screenshots on Android'**
  String get blockScreenshotsSubtitle;

  /// No description provided for @webScreenshotNote.
  ///
  /// In en, this message translates to:
  /// **'Screenshot protection is exclusive to the mobile app'**
  String get webScreenshotNote;

  /// No description provided for @quickHideHeading.
  ///
  /// In en, this message translates to:
  /// **'Quick-Hide'**
  String get quickHideHeading;

  /// No description provided for @quickHideExplanation.
  ///
  /// In en, this message translates to:
  /// **'Tap the eye-off icon in the top header anytime to instantly conceal the screen. If a PIN is active, the app locks; otherwise, a peaceful cover appears until tapped.'**
  String get quickHideExplanation;

  /// No description provided for @testQuickHideButton.
  ///
  /// In en, this message translates to:
  /// **'Test Quick-Hide Now'**
  String get testQuickHideButton;

  /// No description provided for @comingSoonHeading.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoonHeading;

  /// No description provided for @neutralRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Discreet Neutral Reminders'**
  String get neutralRemindersTitle;

  /// No description provided for @neutralRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local reminders with gentle, private wording'**
  String get neutralRemindersSubtitle;

  /// No description provided for @exportDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Export My Data'**
  String get exportDataTitle;

  /// No description provided for @exportDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download a private copy of your records'**
  String get exportDataSubtitle;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and all data'**
  String get deleteAccountSubtitle;

  /// No description provided for @disableLockDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn Off App Lock'**
  String get disableLockDialogTitle;

  /// No description provided for @disableLockDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current PIN to turn off app lock.'**
  String get disableLockDialogBody;

  /// No description provided for @currentPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get currentPinLabel;

  /// No description provided for @pinCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get pinCancel;

  /// No description provided for @turnOffConfirm.
  ///
  /// In en, this message translates to:
  /// **'Turn Off'**
  String get turnOffConfirm;

  /// No description provided for @pinIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get pinIncorrect;

  /// No description provided for @lockDisabledFeedback.
  ///
  /// In en, this message translates to:
  /// **'App lock has been disabled.'**
  String get lockDisabledFeedback;

  /// No description provided for @autoLockTimeoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-Lock Timeout'**
  String get autoLockTimeoutTitle;

  /// No description provided for @timeoutImmediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get timeoutImmediately;

  /// No description provided for @timeout30Seconds.
  ///
  /// In en, this message translates to:
  /// **'30 seconds (Default)'**
  String get timeout30Seconds;

  /// No description provided for @timeout1Minute.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get timeout1Minute;

  /// No description provided for @timeout5Minutes.
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get timeout5Minutes;

  /// No description provided for @quickHideSemanticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Quick hide screen'**
  String get quickHideSemanticsLabel;

  /// No description provided for @cycleOptInTitle.
  ///
  /// In en, this message translates to:
  /// **'CycleCare · Optional Body Rhythm'**
  String get cycleOptInTitle;

  /// No description provided for @cycleOptInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A private, voluntary space to notice your natural cycles.'**
  String get cycleOptInSubtitle;

  /// No description provided for @cycleOptInNoticeHeader.
  ///
  /// In en, this message translates to:
  /// **'Your privacy & how this works'**
  String get cycleOptInNoticeHeader;

  /// No description provided for @cycleOptInNoticeStorage.
  ///
  /// In en, this message translates to:
  /// **'What is stored: Dates and symptoms you choose to enter, kept on the BloomWell server under your account and visible only to you.'**
  String get cycleOptInNoticeStorage;

  /// No description provided for @cycleOptInNoticeEstimates.
  ///
  /// In en, this message translates to:
  /// **'Estimates are suggestions: Any future estimate is an approximation based strictly on your own logs. They can be wrong and vary naturally.'**
  String get cycleOptInNoticeEstimates;

  /// No description provided for @cycleOptInNoticeNonMedical.
  ///
  /// In en, this message translates to:
  /// **'Not medical advice: BloomWell is a self-care wellness companion and never provides medical diagnoses or clinical guidance.'**
  String get cycleOptInNoticeNonMedical;

  /// No description provided for @cycleOptInNoticeControl.
  ///
  /// In en, this message translates to:
  /// **'Always your choice: Cycle tracking is completely optional. You can turn it off or permanently delete your cycle records at any time.'**
  String get cycleOptInNoticeControl;

  /// No description provided for @cycleOptInEnableButton.
  ///
  /// In en, this message translates to:
  /// **'Turn on cycle tracking'**
  String get cycleOptInEnableButton;

  /// No description provided for @cycleOptInNotNowButton.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get cycleOptInNotNowButton;

  /// No description provided for @cycleCalendarHeader.
  ///
  /// In en, this message translates to:
  /// **'Cycle Calendar'**
  String get cycleCalendarHeader;

  /// No description provided for @cycleCalendarPrevMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get cycleCalendarPrevMonth;

  /// No description provided for @cycleCalendarNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get cycleCalendarNextMonth;

  /// No description provided for @cycleLegendLogged.
  ///
  /// In en, this message translates to:
  /// **'Logged period'**
  String get cycleLegendLogged;

  /// No description provided for @cycleLegendEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimated window'**
  String get cycleLegendEstimate;

  /// No description provided for @cycleLegendSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Symptoms logged'**
  String get cycleLegendSymptoms;

  /// No description provided for @cycleDaySheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Day Details'**
  String get cycleDaySheetTitle;

  /// No description provided for @cycleDayNoLogs.
  ///
  /// In en, this message translates to:
  /// **'No period or symptoms logged for this day.'**
  String get cycleDayNoLogs;

  /// No description provided for @cycleDayPeriodLogged.
  ///
  /// In en, this message translates to:
  /// **'Period logged'**
  String get cycleDayPeriodLogged;

  /// No description provided for @cycleDayEstimateWindow.
  ///
  /// In en, this message translates to:
  /// **'Estimated window'**
  String get cycleDayEstimateWindow;

  /// No description provided for @cycleActionLogPeriod.
  ///
  /// In en, this message translates to:
  /// **'Log period'**
  String get cycleActionLogPeriod;

  /// No description provided for @cycleActionLogSymptom.
  ///
  /// In en, this message translates to:
  /// **'Log symptom'**
  String get cycleActionLogSymptom;

  /// No description provided for @cycleActionEditPeriod.
  ///
  /// In en, this message translates to:
  /// **'Edit period'**
  String get cycleActionEditPeriod;

  /// No description provided for @cycleActionDeletePeriod.
  ///
  /// In en, this message translates to:
  /// **'Delete period'**
  String get cycleActionDeletePeriod;

  /// No description provided for @cycleDeletePeriodConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this period log? This action cannot be undone.'**
  String get cycleDeletePeriodConfirm;

  /// No description provided for @cycleQuickStartedToday.
  ///
  /// In en, this message translates to:
  /// **'Period started today'**
  String get cycleQuickStartedToday;

  /// No description provided for @cycleQuickEndedToday.
  ///
  /// In en, this message translates to:
  /// **'Period ended today'**
  String get cycleQuickEndedToday;

  /// No description provided for @cycleQuickPeriodEnded.
  ///
  /// In en, this message translates to:
  /// **'Period ended'**
  String get cycleQuickPeriodEnded;

  /// No description provided for @cycleSwitchToListView.
  ///
  /// In en, this message translates to:
  /// **'Switch to accessible list view'**
  String get cycleSwitchToListView;

  /// No description provided for @cycleSwitchToGridView.
  ///
  /// In en, this message translates to:
  /// **'Switch to calendar grid view'**
  String get cycleSwitchToGridView;

  /// No description provided for @cycleLogPeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Period'**
  String get cycleLogPeriodTitle;

  /// No description provided for @cycleEditPeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Period'**
  String get cycleEditPeriodTitle;

  /// No description provided for @cycleStartDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get cycleStartDateLabel;

  /// No description provided for @cycleEndDateLabel.
  ///
  /// In en, this message translates to:
  /// **'End date (optional)'**
  String get cycleEndDateLabel;

  /// No description provided for @cycleSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get cycleSaveButton;

  /// No description provided for @cycleSavingButton.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get cycleSavingButton;

  /// No description provided for @cycleCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cycleCancelButton;

  /// No description provided for @cyclePeriodSaved.
  ///
  /// In en, this message translates to:
  /// **'Period logged successfully 🌸'**
  String get cyclePeriodSaved;

  /// No description provided for @cyclePeriodDeleted.
  ///
  /// In en, this message translates to:
  /// **'Period record deleted.'**
  String get cyclePeriodDeleted;

  /// No description provided for @cycleErrorFutureDate.
  ///
  /// In en, this message translates to:
  /// **'Start date cannot be in the future.'**
  String get cycleErrorFutureDate;

  /// No description provided for @cycleErrorInvalidRange.
  ///
  /// In en, this message translates to:
  /// **'End date must be on or after the start date.'**
  String get cycleErrorInvalidRange;

  /// No description provided for @cycleErrorOverlap.
  ///
  /// In en, this message translates to:
  /// **'This period overlaps with an already recorded period.'**
  String get cycleErrorOverlap;

  /// No description provided for @cycleLogSymptomTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Symptoms'**
  String get cycleLogSymptomTitle;

  /// No description provided for @cycleEditSymptomTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Symptom'**
  String get cycleEditSymptomTitle;

  /// No description provided for @cycleSymptomDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get cycleSymptomDateLabel;

  /// No description provided for @cycleSymptomTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'What are you noticing?'**
  String get cycleSymptomTypeLabel;

  /// No description provided for @cycleSymptomCramps.
  ///
  /// In en, this message translates to:
  /// **'Cramps'**
  String get cycleSymptomCramps;

  /// No description provided for @cycleSymptomBloating.
  ///
  /// In en, this message translates to:
  /// **'Bloating'**
  String get cycleSymptomBloating;

  /// No description provided for @cycleSymptomFatigue.
  ///
  /// In en, this message translates to:
  /// **'Fatigue'**
  String get cycleSymptomFatigue;

  /// No description provided for @cycleSymptomHeadache.
  ///
  /// In en, this message translates to:
  /// **'Headache'**
  String get cycleSymptomHeadache;

  /// No description provided for @cycleSymptomBackPain.
  ///
  /// In en, this message translates to:
  /// **'Back pain'**
  String get cycleSymptomBackPain;

  /// No description provided for @cycleSymptomBreastTenderness.
  ///
  /// In en, this message translates to:
  /// **'Breast tenderness'**
  String get cycleSymptomBreastTenderness;

  /// No description provided for @cycleSymptomNausea.
  ///
  /// In en, this message translates to:
  /// **'Nausea'**
  String get cycleSymptomNausea;

  /// No description provided for @cycleSymptomMoodChanges.
  ///
  /// In en, this message translates to:
  /// **'Mood changes'**
  String get cycleSymptomMoodChanges;

  /// No description provided for @cycleSymptomAcne.
  ///
  /// In en, this message translates to:
  /// **'Acne'**
  String get cycleSymptomAcne;

  /// No description provided for @cycleSymptomCravings.
  ///
  /// In en, this message translates to:
  /// **'Cravings'**
  String get cycleSymptomCravings;

  /// No description provided for @cycleSymptomSleepTrouble.
  ///
  /// In en, this message translates to:
  /// **'Sleep trouble'**
  String get cycleSymptomSleepTrouble;

  /// No description provided for @cycleSymptomOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get cycleSymptomOther;

  /// No description provided for @cycleCustomLabelLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom symptom name'**
  String get cycleCustomLabelLabel;

  /// No description provided for @cycleCustomLabelPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Lower pelvic ache'**
  String get cycleCustomLabelPlaceholder;

  /// No description provided for @cycleSeverityLabel.
  ///
  /// In en, this message translates to:
  /// **'Severity: {label}'**
  String cycleSeverityLabel(String label);

  /// No description provided for @cycleSeverity1.
  ///
  /// In en, this message translates to:
  /// **'Barely noticeable'**
  String get cycleSeverity1;

  /// No description provided for @cycleSeverity2.
  ///
  /// In en, this message translates to:
  /// **'Mild'**
  String get cycleSeverity2;

  /// No description provided for @cycleSeverity3.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get cycleSeverity3;

  /// No description provided for @cycleSeverity4.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get cycleSeverity4;

  /// No description provided for @cycleSeverity5.
  ///
  /// In en, this message translates to:
  /// **'Very strong'**
  String get cycleSeverity5;

  /// No description provided for @cycleSeverityDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'If symptoms feel severe or worrying, talking to a doctor or nurse can help.'**
  String get cycleSeverityDisclaimer;

  /// No description provided for @cycleNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get cycleNotesLabel;

  /// No description provided for @cycleNotesPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'How does this feel? Any gentle observations...'**
  String get cycleNotesPlaceholder;

  /// No description provided for @cycleNotesCounter.
  ///
  /// In en, this message translates to:
  /// **'{count} / 500'**
  String cycleNotesCounter(int count);

  /// No description provided for @cycleSymptomSaved.
  ///
  /// In en, this message translates to:
  /// **'Symptom logged successfully 🌸'**
  String get cycleSymptomSaved;

  /// No description provided for @cycleSymptomDeleted.
  ///
  /// In en, this message translates to:
  /// **'Symptom record deleted.'**
  String get cycleSymptomDeleted;

  /// No description provided for @cycleDeleteSymptomConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this symptom log? This action cannot be undone.'**
  String get cycleDeleteSymptomConfirm;

  /// No description provided for @cycleEstimateTitle.
  ///
  /// In en, this message translates to:
  /// **'Cycle Observation'**
  String get cycleEstimateTitle;

  /// No description provided for @cycleEstimateBadge.
  ///
  /// In en, this message translates to:
  /// **'Estimate'**
  String get cycleEstimateBadge;

  /// No description provided for @cycleEstimateDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This is an estimate and can be wrong. It is not medical advice.'**
  String get cycleEstimateDisclaimer;

  /// No description provided for @cycleEstimateNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Log a few more periods to see an estimate ({count} more needed).'**
  String cycleEstimateNotEnoughData(int count);

  /// No description provided for @cycleEstimateTooVariable.
  ///
  /// In en, this message translates to:
  /// **'Your logged cycles vary too much for a useful estimate.'**
  String get cycleEstimateTooVariable;

  /// No description provided for @cycleEstimateRange.
  ///
  /// In en, this message translates to:
  /// **'Next period expected around {rangeStart} to {rangeEnd}.'**
  String cycleEstimateRange(String rangeStart, String rangeEnd);

  /// No description provided for @cycleEstimateDetails.
  ///
  /// In en, this message translates to:
  /// **'Typical length: {days} days · Based on your last {count} logged cycles.'**
  String cycleEstimateDetails(int days, int count);

  /// No description provided for @cycleHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Recorded Cycles'**
  String get cycleHistoryTitle;

  /// No description provided for @cycleHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cycles recorded yet. Your logged periods will appear here.'**
  String get cycleHistoryEmpty;

  /// No description provided for @cycleHistoryCycleLength.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String cycleHistoryCycleLength(int days);

  /// No description provided for @cycleHistoryOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get cycleHistoryOngoing;

  /// No description provided for @cycleHistoryDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get cycleHistoryDelete;

  /// No description provided for @cycleHistoryEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get cycleHistoryEdit;

  /// No description provided for @cycleSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'CycleCare Settings'**
  String get cycleSettingsTitle;

  /// No description provided for @cycleTurnOffTracking.
  ///
  /// In en, this message translates to:
  /// **'Turn off cycle tracking'**
  String get cycleTurnOffTracking;

  /// No description provided for @cycleTurnOffDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn Off Cycle Tracking?'**
  String get cycleTurnOffDialogTitle;

  /// No description provided for @cycleTurnOffDialogBody.
  ///
  /// In en, this message translates to:
  /// **'You can choose to keep your existing cycle records or delete them permanently from the server.'**
  String get cycleTurnOffDialogBody;

  /// No description provided for @cycleKeepDataOption.
  ///
  /// In en, this message translates to:
  /// **'Turn off and keep my data'**
  String get cycleKeepDataOption;

  /// No description provided for @cycleDeleteDataOption.
  ///
  /// In en, this message translates to:
  /// **'Turn off and delete my cycle data'**
  String get cycleDeleteDataOption;

  /// No description provided for @cycleDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Permanent Deletion'**
  String get cycleDeleteConfirmTitle;

  /// No description provided for @cycleDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your logged periods and cycle symptoms from the server. This action cannot be undone.'**
  String get cycleDeleteConfirmBody;

  /// No description provided for @cycleConfirmDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete All Cycle Data'**
  String get cycleConfirmDeleteButton;

  /// No description provided for @cycleTrackingDisabledFeedback.
  ///
  /// In en, this message translates to:
  /// **'Cycle tracking has been turned off.'**
  String get cycleTrackingDisabledFeedback;

  /// No description provided for @cycleTrackingDeletedFeedback.
  ///
  /// In en, this message translates to:
  /// **'Cycle tracking turned off and all data deleted.'**
  String get cycleTrackingDeletedFeedback;

  /// No description provided for @homeCycleCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Check in with your body'**
  String get homeCycleCardTitle;

  /// No description provided for @homeCycleCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notice your energy and rhythm today'**
  String get homeCycleCardSubtitle;

  /// No description provided for @homeCycleCardAction.
  ///
  /// In en, this message translates to:
  /// **'Open CycleCare'**
  String get homeCycleCardAction;

  /// No description provided for @cycleDisabledNotice.
  ///
  /// In en, this message translates to:
  /// **'Cycle tracking is currently off. Turn it on anytime to start logging.'**
  String get cycleDisabledNotice;

  /// No description provided for @selfCareStudioTitle.
  ///
  /// In en, this message translates to:
  /// **'Self-Care Studio'**
  String get selfCareStudioTitle;

  /// No description provided for @selfCareStudioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Curated gentle practices for body, mind, and study breaks.'**
  String get selfCareStudioSubtitle;

  /// No description provided for @selfCareCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get selfCareCategoryAll;

  /// No description provided for @selfCareCategoryBreathing.
  ///
  /// In en, this message translates to:
  /// **'Breathing'**
  String get selfCareCategoryBreathing;

  /// No description provided for @selfCareCategoryGrounding.
  ///
  /// In en, this message translates to:
  /// **'Grounding'**
  String get selfCareCategoryGrounding;

  /// No description provided for @selfCareCategoryRelaxation.
  ///
  /// In en, this message translates to:
  /// **'Relaxation'**
  String get selfCareCategoryRelaxation;

  /// No description provided for @selfCareCategoryMovement.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get selfCareCategoryMovement;

  /// No description provided for @selfCareCategoryJournaling.
  ///
  /// In en, this message translates to:
  /// **'Journaling'**
  String get selfCareCategoryJournaling;

  /// No description provided for @selfCareCategoryStudyBreak.
  ///
  /// In en, this message translates to:
  /// **'Study Break'**
  String get selfCareCategoryStudyBreak;

  /// No description provided for @selfCareCategoryComfort.
  ///
  /// In en, this message translates to:
  /// **'Comfort'**
  String get selfCareCategoryComfort;

  /// No description provided for @selfCareCategoryConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get selfCareCategoryConfidence;

  /// No description provided for @selfCareDurationAny.
  ///
  /// In en, this message translates to:
  /// **'Any duration'**
  String get selfCareDurationAny;

  /// No description provided for @selfCareDuration2.
  ///
  /// In en, this message translates to:
  /// **'Up to 2 min'**
  String get selfCareDuration2;

  /// No description provided for @selfCareDuration5.
  ///
  /// In en, this message translates to:
  /// **'Up to 5 min'**
  String get selfCareDuration5;

  /// No description provided for @selfCareDuration10.
  ///
  /// In en, this message translates to:
  /// **'Up to 10 min'**
  String get selfCareDuration10;

  /// No description provided for @selfCareEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No activities match this filter'**
  String get selfCareEmptyTitle;

  /// No description provided for @selfCareEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try choosing a different category or longer duration.'**
  String get selfCareEmptySubtitle;

  /// No description provided for @selfCareErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load studio activities'**
  String get selfCareErrorTitle;

  /// No description provided for @selfCareRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get selfCareRetry;

  /// No description provided for @selfCareHistoryButton.
  ///
  /// In en, this message translates to:
  /// **'My activity history'**
  String get selfCareHistoryButton;

  /// No description provided for @selfCareRoutinesButton.
  ///
  /// In en, this message translates to:
  /// **'Routines'**
  String get selfCareRoutinesButton;

  /// No description provided for @selfCareAddFavoriteA11y.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get selfCareAddFavoriteA11y;

  /// No description provided for @selfCareRemoveFavoriteA11y.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get selfCareRemoveFavoriteA11y;

  /// No description provided for @selfCareDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String selfCareDurationMinutes(int count);

  /// No description provided for @activityDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity Details'**
  String get activityDetailTitle;

  /// No description provided for @activityStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start gentle guide'**
  String get activityStartButton;

  /// No description provided for @activitySourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get activitySourceLabel;

  /// No description provided for @activityStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Guided Steps'**
  String get activityStepsTitle;

  /// No description provided for @activityComfortDoctorNote.
  ///
  /// In en, this message translates to:
  /// **'If symptoms feel severe, unusual or last a long time, talking to a doctor or nurse can help.'**
  String get activityComfortDoctorNote;

  /// No description provided for @activityStepCounter.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String activityStepCounter(int current, int total);

  /// No description provided for @activityStepNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get activityStepNext;

  /// No description provided for @activityStepBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get activityStepBack;

  /// No description provided for @activityStepDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get activityStepDone;

  /// No description provided for @activityRatingTitle.
  ///
  /// In en, this message translates to:
  /// **'Did this help?'**
  String get activityRatingTitle;

  /// No description provided for @activityRatingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional feedback to help suggest gentler activities for you.'**
  String get activityRatingSubtitle;

  /// No description provided for @activityRatingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get activityRatingSkip;

  /// No description provided for @activitySavedConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Activity completed and logged gently.'**
  String get activitySavedConfirmed;

  /// No description provided for @activityHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'My Activity History'**
  String get activityHistoryTitle;

  /// No description provided for @activityHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'A quiet record of your gentle moments.'**
  String get activityHistorySubtitle;

  /// No description provided for @activityHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No completed activities yet. Take your time.'**
  String get activityHistoryEmpty;

  /// No description provided for @comfortModeTitle.
  ///
  /// In en, this message translates to:
  /// **'A gentle moment'**
  String get comfortModeTitle;

  /// No description provided for @comfortModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No pressure. Pick what feels okay right now.'**
  String get comfortModeSubtitle;

  /// No description provided for @comfortNeedQuestion.
  ///
  /// In en, this message translates to:
  /// **'What do you need?'**
  String get comfortNeedQuestion;

  /// No description provided for @comfortNeedQuickBreak.
  ///
  /// In en, this message translates to:
  /// **'A quick break'**
  String get comfortNeedQuickBreak;

  /// No description provided for @comfortNeedCalmDown.
  ///
  /// In en, this message translates to:
  /// **'Calm down'**
  String get comfortNeedCalmDown;

  /// No description provided for @comfortNeedBodyComfort.
  ///
  /// In en, this message translates to:
  /// **'Body comfort'**
  String get comfortNeedBodyComfort;

  /// No description provided for @comfortNeedFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get comfortNeedFocus;

  /// No description provided for @comfortReasonFavorite.
  ///
  /// In en, this message translates to:
  /// **'One of your favorites'**
  String get comfortReasonFavorite;

  /// No description provided for @comfortReasonNewForYou.
  ///
  /// In en, this message translates to:
  /// **'Something new to try'**
  String get comfortReasonNewForYou;

  /// No description provided for @comfortReasonQuick.
  ///
  /// In en, this message translates to:
  /// **'Gentle and quick'**
  String get comfortReasonQuick;

  /// No description provided for @comfortReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Suggested for you'**
  String get comfortReasonOther;

  /// No description provided for @comfortShowSomethingElse.
  ///
  /// In en, this message translates to:
  /// **'Show me something else'**
  String get comfortShowSomethingElse;

  /// No description provided for @comfortPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'My comfort plan'**
  String get comfortPlanTitle;

  /// No description provided for @comfortPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your saved soothing practices for difficult days.'**
  String get comfortPlanSubtitle;

  /// No description provided for @comfortPlanEmpty.
  ///
  /// In en, this message translates to:
  /// **'No practices in your plan yet. Save a few favorites here for easy access.'**
  String get comfortPlanEmpty;

  /// No description provided for @comfortAddToPlan.
  ///
  /// In en, this message translates to:
  /// **'Add to comfort plan'**
  String get comfortAddToPlan;

  /// No description provided for @comfortRemoveFromPlan.
  ///
  /// In en, this message translates to:
  /// **'Remove from plan'**
  String get comfortRemoveFromPlan;

  /// No description provided for @comfortFindSupport.
  ///
  /// In en, this message translates to:
  /// **'Find support'**
  String get comfortFindSupport;

  /// No description provided for @comfortNonMedicalNotice.
  ///
  /// In en, this message translates to:
  /// **'BloomWell is not a medical or emergency service. If you are going through a difficult time, reaching out to a trusted person or health professional can help.'**
  String get comfortNonMedicalNotice;

  /// No description provided for @routinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Routines'**
  String get routinesTitle;

  /// No description provided for @routinesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gentle rituals to nourish your rhythm without pressure.'**
  String get routinesSubtitle;

  /// No description provided for @routinesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No routines created yet'**
  String get routinesEmptyTitle;

  /// No description provided for @routinesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a soothing daily or weekly routine that feels good to you.'**
  String get routinesEmptySubtitle;

  /// No description provided for @routinesNewButton.
  ///
  /// In en, this message translates to:
  /// **'New routine'**
  String get routinesNewButton;

  /// No description provided for @routinesCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Routine'**
  String get routinesCreateTitle;

  /// No description provided for @routinesEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Routine'**
  String get routinesEditTitle;

  /// No description provided for @routinesTitleField.
  ///
  /// In en, this message translates to:
  /// **'Routine Title'**
  String get routinesTitleField;

  /// No description provided for @routinesStartDateField.
  ///
  /// In en, this message translates to:
  /// **'Start Date (optional)'**
  String get routinesStartDateField;

  /// No description provided for @routinesEndDateField.
  ///
  /// In en, this message translates to:
  /// **'End Date (optional)'**
  String get routinesEndDateField;

  /// No description provided for @routinesSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Routine'**
  String get routinesSaveButton;

  /// No description provided for @routinesDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get routinesDeleteButton;

  /// No description provided for @routinesDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this routine?'**
  String get routinesDeleteConfirm;

  /// No description provided for @routinesAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add activity'**
  String get routinesAddItem;

  /// No description provided for @routinesLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'You have reached the maximum limit of 20 routines.'**
  String get routinesLimitExceeded;

  /// No description provided for @routinesItemLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'You have reached the maximum limit of 50 activities for this routine.'**
  String get routinesItemLimitExceeded;

  /// No description provided for @routinesProgressText.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} done'**
  String routinesProgressText(int completed, int total);

  /// No description provided for @examsTitle.
  ///
  /// In en, this message translates to:
  /// **'Exams & Deadlines'**
  String get examsTitle;

  /// No description provided for @examsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep track of academic events so study suggestions can feel gentler.'**
  String get examsSubtitle;

  /// No description provided for @examsPlannerNotice.
  ///
  /// In en, this message translates to:
  /// **'Adding exams and deadlines lets BloomWell suggest gentler study plans later. This is optional.'**
  String get examsPlannerNotice;

  /// No description provided for @examsPlannerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Study planner coming soon'**
  String get examsPlannerComingSoon;

  /// No description provided for @examsTabUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get examsTabUpcoming;

  /// No description provided for @examsTabPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get examsTabPast;

  /// No description provided for @examsNewButton.
  ///
  /// In en, this message translates to:
  /// **'Add deadline or exam'**
  String get examsNewButton;

  /// No description provided for @examsCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Academic Event'**
  String get examsCreateTitle;

  /// No description provided for @examsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Academic Event'**
  String get examsEditTitle;

  /// No description provided for @examsTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title (max 80 chars)'**
  String get examsTitleLabel;

  /// No description provided for @examsDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Event Date'**
  String get examsDateLabel;

  /// No description provided for @examsTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Event Type'**
  String get examsTypeLabel;

  /// No description provided for @examsTypeExam.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get examsTypeExam;

  /// No description provided for @examsTypeAssignment.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get examsTypeAssignment;

  /// No description provided for @examsTypePresentation.
  ///
  /// In en, this message translates to:
  /// **'Presentation'**
  String get examsTypePresentation;

  /// No description provided for @examsTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get examsTypeOther;

  /// No description provided for @examsSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Event'**
  String get examsSaveButton;

  /// No description provided for @examsDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get examsDeleteButton;

  /// No description provided for @examsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this event?'**
  String get examsDeleteConfirm;

  /// No description provided for @examsEmptyUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No upcoming exams or deadlines entered. Enjoy your free rhythm.'**
  String get examsEmptyUpcoming;

  /// No description provided for @examsEmptyPast.
  ///
  /// In en, this message translates to:
  /// **'No past exams recorded.'**
  String get examsEmptyPast;

  /// No description provided for @examsInDays.
  ///
  /// In en, this message translates to:
  /// **'in {days} days'**
  String examsInDays(int days);

  /// No description provided for @examsInOneDay.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get examsInOneDay;

  /// No description provided for @examsToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get examsToday;

  /// No description provided for @examsDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String examsDaysAgo(int days);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
