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
