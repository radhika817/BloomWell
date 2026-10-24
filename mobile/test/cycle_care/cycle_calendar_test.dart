import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloomwell/features/cycle_care/application/cycle_care_notifier.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_estimate.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_period_entry.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_symptom_entry.dart';
import 'package:bloomwell/features/cycle_care/presentation/widgets/cycle_month_calendar.dart';
import 'package:bloomwell/l10n/app_localizations.dart';

Widget createTestableWidget({
  required Widget child,
  double textScaleFactor = 1.0,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: SingleChildScrollView(
        child: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  group('CycleMonthCalendar Widget & Accessibility Tests', () {
    final testMonth = DateTime(2026, 10, 1);
    final testPeriods = [
      const CyclePeriodEntry(
        id: 'p-1',
        clientId: 'c-1',
        periodStart: '2026-10-05',
        periodEnd: '2026-10-08',
        cycleLengthDays: 28,
      ),
    ];
    final testSymptoms = [
      const CycleSymptomEntry(
        id: 's-1',
        clientId: 'cs-1',
        date: '2026-10-06',
        symptomType: CycleSymptomType.cramps,
        severity: 3,
      ),
    ];
    const testEstimate = CycleEstimate(
      status: CycleEstimateStatus.estimate,
      estimatedRangeStart: '2026-10-25',
      estimatedRangeEnd: '2026-10-28',
      typicalCycleLengthDays: 28,
    );

    testWidgets('Renders month header, weekdays, days, and visual legend',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestableWidget(
          child: CycleMonthCalendar(
            selectedMonth: testMonth,
            selectedDate: DateTime(2026, 10, 5),
            viewMode: CalendarViewMode.grid,
            monthCycles: testPeriods,
            monthSymptoms: testSymptoms,
            estimate: testEstimate,
            onDaySelected: (_) {},
            onPreviousMonth: () {},
            onNextMonth: () {},
            onToggleViewMode: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Logged period'), findsOneWidget);
      expect(find.text('Estimated window'), findsOneWidget);
      expect(find.text('Symptoms logged'), findsOneWidget);

      // Verify water drop icon is shown for logged periods
      expect(find.byIcon(Icons.water_drop_rounded), findsWidgets);
    });

    testWidgets('Tapping a day cell triggers onDaySelected', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      DateTime? tappedDay;
      await tester.pumpWidget(
        createTestableWidget(
          child: CycleMonthCalendar(
            selectedMonth: testMonth,
            selectedDate: null,
            viewMode: CalendarViewMode.grid,
            monthCycles: testPeriods,
            monthSymptoms: testSymptoms,
            estimate: testEstimate,
            onDaySelected: (d) => tappedDay = d,
            onPreviousMonth: () {},
            onNextMonth: () {},
            onToggleViewMode: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dayCell = find.byKey(const Key('cycle_day_grid_15'));
      await tester.tap(dayCell);
      await tester.pumpAndSettle();

      expect(tappedDay, equals(DateTime(2026, 10, 15)));
    });

    testWidgets('Navigation buttons trigger callbacks', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool prevCalled = false;
      bool nextCalled = false;
      bool toggleCalled = false;

      await tester.pumpWidget(
        createTestableWidget(
          child: CycleMonthCalendar(
            selectedMonth: testMonth,
            selectedDate: null,
            viewMode: CalendarViewMode.grid,
            monthCycles: testPeriods,
            monthSymptoms: testSymptoms,
            estimate: testEstimate,
            onDaySelected: (_) {},
            onPreviousMonth: () => prevCalled = true,
            onNextMonth: () => nextCalled = true,
            onToggleViewMode: () => toggleCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cycle_cal_prev_month')));
      expect(prevCalled, isTrue);

      await tester.tap(find.byKey(const Key('cycle_cal_next_month')));
      expect(nextCalled, isTrue);

      await tester.tap(find.byKey(const Key('cycle_cal_view_toggle')));
      expect(toggleCalled, isTrue);
    });

    testWidgets('Accessible List View mode renders scrollable day items',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      DateTime? tappedDay;
      await tester.pumpWidget(
        createTestableWidget(
          child: CycleMonthCalendar(
            selectedMonth: testMonth,
            selectedDate: DateTime(2026, 10, 6),
            viewMode: CalendarViewMode.list,
            monthCycles: testPeriods,
            monthSymptoms: testSymptoms,
            estimate: testEstimate,
            onDaySelected: (d) => tappedDay = d,
            onPreviousMonth: () {},
            onNextMonth: () {},
            onToggleViewMode: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // List view item for day 6 should have period badge and symptom count
      expect(find.byKey(const Key('cycle_day_list_6')), findsOneWidget);
      expect(find.text('1 symptoms'), findsOneWidget);

      await tester.tap(find.byKey(const Key('cycle_day_list_12')));
      await tester.pumpAndSettle();
      expect(tappedDay, equals(DateTime(2026, 10, 12)));
    });

    testWidgets('Day cells meet minimum tap target size (>= 48x48)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestableWidget(
          child: CycleMonthCalendar(
            selectedMonth: testMonth,
            selectedDate: null,
            viewMode: CalendarViewMode.grid,
            monthCycles: testPeriods,
            monthSymptoms: testSymptoms,
            estimate: testEstimate,
            onDaySelected: (_) {},
            onPreviousMonth: () {},
            onNextMonth: () {},
            onToggleViewMode: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dayCell = find.byKey(const Key('cycle_day_grid_10'));
      final size = tester.getSize(dayCell);
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('Renders properly under 200% accessibility text scale',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestableWidget(
          textScaleFactor: 2.0,
          child: CycleMonthCalendar(
            selectedMonth: testMonth,
            selectedDate: null,
            viewMode: CalendarViewMode.grid,
            monthCycles: testPeriods,
            monthSymptoms: testSymptoms,
            estimate: testEstimate,
            onDaySelected: (_) {},
            onPreviousMonth: () {},
            onNextMonth: () {},
            onToggleViewMode: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('October 2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
