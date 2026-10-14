import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloomwell/app/app.dart';

void main() {
  Widget createTestWidget() {
    return const ProviderScope(
      child: BloomWellApp(),
    );
  }

  testWidgets('BloomWell loads with home screen and key elements',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify Greeting and Subtitle
    expect(find.text('Hey, lovely! 🌷'), findsOneWidget);
    expect(find.text('Take a little moment for yourself.'), findsOneWidget);

    // Verify the 5 Moods exist
    expect(find.text('Happy'), findsOneWidget);
    expect(find.text('Calm'), findsOneWidget);
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
    expect(find.text('CycleCare'), findsWidgets); // Self-care card + bottom nav
    expect(find.text('Breathe & Relax'), findsOneWidget);
    expect(
        find.text('Bloom Buddy'), findsWidgets); // Self-care card + bottom nav
    expect(find.text('Coming soon'), findsWidgets);

    // Verify Mindful Breathing
    expect(find.text('Mindful Breathing'), findsOneWidget);
    expect(find.text('about 2 min'), findsWidgets);
  });

  testWidgets('Mood selection updates Riverpod state and shows affirmation',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap on 'Calm' mood button
    await tester.tap(find.text('Calm'));
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
    await tester.tap(find.text('Try Comfort Mode'));
    await tester.pumpAndSettle();

    // Verify Comfort Mode placeholder opened
    expect(find.text('Comfort Mode'), findsWidgets);
    expect(find.text('Coming in a later update'), findsOneWidget);

    // Return to Home
    await tester.ensureVisible(find.text('Back to Home'));
    await tester.tap(find.text('Back to Home'));
    await tester.pumpAndSettle();

    expect(find.text('Hey, lovely! 🌷'), findsOneWidget);
  });

  testWidgets('GoRouter navigation to Study Planner placeholder',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Scroll and tap "Plan my study week 📚"
    await tester.ensureVisible(find.text('Plan my study week 📚'));
    await tester.tap(find.text('Plan my study week 📚'));
    await tester.pumpAndSettle();

    // Verify Study Planner placeholder appears
    expect(find.text('Study Planner'), findsWidgets);
    expect(find.text('Coming in a later update'), findsOneWidget);

    // Return to Home
    await tester.ensureVisible(find.text('Back to Home'));
    await tester.tap(find.text('Back to Home'));
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
}
