import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloomwell/app/app.dart';
import 'package:bloomwell/features/home/presentation/widgets/mood_checkin_card.dart';

void main() {
  testWidgets('BloomWell loads with home screen and key elements',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BloomWellApp());
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

    // Verify Daily Bloom Thought encouragement card
    expect(find.text('Daily Bloom Thought'), findsOneWidget);

    // Verify Self-Care Routines section
    expect(find.text('Self-Care Routines 🌿'), findsOneWidget);
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('CycleCare'), findsWidgets); // Self-care card + bottom nav
    expect(find.text('Breathe & Relax'), findsOneWidget);
    expect(
        find.text('Bloom Buddy'), findsWidgets); // Self-care card + bottom nav

    // Verify Mindful Breathing
    expect(find.text('Mindful Breathing'), findsOneWidget);
  });

  testWidgets('Mood selection updates local state and shows affirmation',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BloomWellApp());
    await tester.pumpAndSettle();

    // Tap on 'Calm' mood button
    await tester.tap(find.text('Calm'));
    await tester.pumpAndSettle();

    // Verify Calm affirmation is displayed
    expect(find.text(BloomMood.calm.affirmation), findsOneWidget);
    expect(find.text('Session check-in · Not persisted'), findsOneWidget);

    // Tap Reset
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    // Verify affirmation is no longer displayed
    expect(find.text(BloomMood.calm.affirmation), findsNothing);
  });

  testWidgets('Bottom navigation switches tabs and shows honest placeholder',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BloomWellApp());
    await tester.pumpAndSettle();

    // Tap on Profile tab in bottom navigation bar
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();

    // Verify Profile placeholder appears (present in AppBar and body)
    expect(find.text('Profile & Privacy Center'), findsWidgets);
    expect(find.text('Phase 4 Feature'), findsOneWidget);

    // Tap Back to Home button (scroll into view if needed)
    await tester.ensureVisible(find.text('Back to Home'));
    await tester.tap(find.text('Back to Home'));
    await tester.pumpAndSettle();

    // Verify Home greeting is visible again
    expect(find.text('Hey, lovely! 🌷'), findsOneWidget);
  });
}
