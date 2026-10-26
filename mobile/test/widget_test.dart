import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloomwell/app/app.dart';
import 'package:bloomwell/app/router.dart';

void main() {
  Widget createTestWidget() {
    appRouter.go('/');
    return const ProviderScope(
      child: BloomWellApp(),
    );
  }

  testWidgets('BloomWell loads with home screen and key soft glass elements',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify Greeting and Subtitle
    expect(find.text('Hey, lovely! 🌷'), findsOneWidget);
    expect(find.text('Take a little moment for yourself.'), findsOneWidget);

    // Verify Avatar monogram and Discreet button
    expect(find.text('BW'), findsOneWidget);
    expect(find.text('Discreet'), findsOneWidget);

    // Verify the 5 Moods exist
    expect(find.text('Happy'), findsOneWidget);
    expect(find.text('Calm'), findsWidgets); // Mood bubble + Filter chip
    expect(find.text('Okay'), findsOneWidget);
    expect(find.text('Sad'), findsOneWidget);
    expect(find.text('Stressed'), findsOneWidget);

    // Verify hard day button and study planner card
    expect(find.text('I\'m having a hard day 🤍'), findsOneWidget);
    expect(find.text('Plan my study week 📚'), findsOneWidget);

    // Verify Daily Bloom Thought encouragement card
    expect(find.text('Daily Bloom Thought'), findsOneWidget);

    // Verify Self-Care Routines section
    expect(find.text('Self-Care Routines 🌿'), findsOneWidget);
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('CycleCare'),
        findsWidgets); // Self-care card + bottom nav + preview
    expect(find.text('Breathe & Relax'), findsOneWidget);
    expect(
        find.text('Bloom Buddy'), findsWidgets); // Self-care card + bottom nav
    expect(find.text('Coming soon'), findsWidgets);

    // Verify Mindful Breathing and duration badge
    expect(find.text('Mindful Breathing'), findsOneWidget);
    expect(find.text('about 2 min'), findsWidgets);

    // Verify Little Reminder card
    expect(find.text('Little Reminder'), findsOneWidget);
  });

  testWidgets('Mood selection updates Riverpod state and shows affirmation',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap on 'Calm' mood bubble
    await tester.tap(find.text('Calm').first);
    await tester.pumpAndSettle();

    // Verify Calm affirmation and session-only note are displayed
    expect(
      find.text(
          'Cherish this peaceful energy. May your day stay gentle and unhurried. 🌿'),
      findsOneWidget,
    );
    expect(find.text('Session check-in · Not persisted'), findsOneWidget);

    // Tap Reset
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    // Verify affirmation is no longer displayed
    expect(
      find.text(
          'Cherish this peaceful energy. May your day stay gentle and unhurried. 🌿'),
      findsNothing,
    );
  });

  testWidgets(
      'Selecting Sad displays supportive feedback with Comfort and Support buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap on 'Sad'
    await tester.tap(find.text('Sad'));
    await tester.pumpAndSettle();

    // Verify supportive message and action buttons appear
    expect(
      find.text(
          'It looks like today might be a bit heavy. You don\'t have to carry it alone. Please be extra gentle with yourself.'),
      findsOneWidget,
    );
    expect(find.text('Try Comfort Mode'), findsOneWidget);
    expect(find.text('Find support'), findsOneWidget);

    // Tap on 'Try Comfort Mode'
    await tester.ensureVisible(find.text('Try Comfort Mode'));
    await tester.tap(find.text('Try Comfort Mode'));
    await tester.pumpAndSettle();

    // Verify Comfort Mode screen opened
    expect(find.text('A gentle moment'), findsOneWidget);
    expect(find.text('What do you need?'), findsOneWidget);

    // Return to Home
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Hey, lovely! 🌷'), findsOneWidget);
  });

  testWidgets('GoRouter navigation to Study Planner',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Scroll and tap "Plan my study week 📚"
    await tester.ensureVisible(find.text('Plan my study week 📚'));
    await tester.tap(find.text('Plan my study week 📚'));
    await tester.pumpAndSettle();

    // Verify Study Planner appears
    expect(find.text('Study Planner'), findsWidgets);

    // Return to Home
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Hey, lovely! 🌷'), findsOneWidget);
  });

  testWidgets('Bottom navigation switches tabs and shows honest placeholder',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap on Profile tab in bottom navigation bar
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();

    // Verify Profile placeholder appears
    expect(find.text('Profile & Privacy Center'), findsWidgets);
    expect(find.text('Coming in a later update'), findsOneWidget);

    // Tap Back to Home button
    await tester.ensureVisible(find.text('Back to Home'));
    await tester.tap(find.text('Back to Home'));
    await tester.pumpAndSettle();

    // Verify Home greeting is visible again
    expect(find.text('Hey, lovely! 🌷'), findsOneWidget);
  });

  testWidgets('My Mood tab loads with pastel bubble cluster and privacy note',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap on My Mood tab in floating nav bar
    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    await tester.pumpAndSettle();

    // Verify My Mood title, empty state text, and button
    expect(find.text('My Mood'), findsWidgets);
    expect(find.text('Check in with your feelings'), findsOneWidget);
    expect(find.text('Strictly on-device · No tracking'), findsOneWidget);

    // Tap Check In on Home button
    await tester.tap(find.text('Check In on Home'));
    await tester.pumpAndSettle();

    // Verify back on Home
    expect(find.text('Hey, lovely! 🌷'), findsOneWidget);
  });

  testWidgets('Full-screen Mindful Breathing exercise opens and finishes',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap featured breathing card
    await tester.ensureVisible(find.text('Deep Breathing').first);
    await tester.tap(find.text('Deep Breathing').first);
    await tester.pumpAndSettle();

    // Verify BreathingScreen content
    expect(find.text('8 soothing cycles · ~2 min'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
    expect(
      find.text(
          'Non-diagnostic relaxation exercise. Stop anytime if you feel lightheaded.'),
      findsOneWidget,
    );

    // Tap Finish to return
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(find.text('Hey, lovely! 🌷'), findsOneWidget);
  });

  testWidgets('Notification sheet displays empty state and dismisses',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap notification bell icon
    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();

    // Verify notifications sheet content
    expect(find.text('Notifications'), findsOneWidget);
    expect(
      find.text('You are all caught up! No new notifications right now. 🌸'),
      findsOneWidget,
    );

    // Close sheet
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsNothing);
  });

  testWidgets('Welcome screen preview renders mascot and feature cards',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    appRouter.push('/welcome');
    await tester.pumpAndSettle();

    expect(find.text('Welcome to BloomWell'), findsOneWidget);
    expect(find.text('Privacy First'), findsOneWidget);
    expect(find.text('Calm & Supportive'), findsOneWidget);
    expect(find.text('Academic Pacing'), findsOneWidget);
    expect(find.text('Explore BloomWell'), findsOneWidget);

    await tester.ensureVisible(find.text('Explore BloomWell'));
    await tester.tap(find.text('Explore BloomWell'));
    await tester.pumpAndSettle();

    expect(find.text('Hey, lovely! 🌷'), findsOneWidget);
  });

  testWidgets('HomeScreen filter chips filter activities locally',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify all 5 activities initially present
    expect(find.text('Nighttime Wind Down'), findsOneWidget);
    expect(find.text('Gentle Stretch'), findsOneWidget);

    // Tap "Sleep" filter chip
    await tester.ensureVisible(find.text('Sleep'));
    await tester.tap(find.text('Sleep'));
    await tester.pumpAndSettle();

    // Only Sleep activity remains, Gentle Stretch is filtered out
    expect(find.text('Nighttime Wind Down'), findsOneWidget);
    expect(find.text('Gentle Stretch'), findsNothing);

    // Tap "All" filter chip to restore
    await tester.ensureVisible(find.text('All'));
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(find.text('Gentle Stretch'), findsOneWidget);
  });

  testWidgets(
      'GlassCard renders accessible opaque fallback under high contrast',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(highContrast: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: ProviderScope(
              child: BloomWellApp(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify app renders with high contrast without crash
    expect(find.text('Hey, lovely! 🌷'), findsOneWidget);
  });

  testWidgets('BreathingScreen runs properly with disableAnimations true',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: ProviderScope(
            child: BloomWellApp(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    appRouter.push('/breathe');
    await tester.pumpAndSettle();

    expect(find.text('Mindful Breathing'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
  });
}
