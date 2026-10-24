import 'package:bloomwell/app/router.dart';
import 'package:bloomwell/features/app_lock/application/app_lock_notifier.dart';
import 'package:bloomwell/features/app_lock/data/biometric_service.dart';
import 'package:bloomwell/features/app_lock/data/security_platform_channel.dart';
import 'package:bloomwell/features/cycle_care/application/cycle_care_notifier.dart';
import 'package:bloomwell/features/cycle_care/data/cycle_care_repository.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_estimate.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_history_insight.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_period_entry.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_symptom_entry.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_tracking_status.dart';
import 'package:bloomwell/features/app_lock/presentation/lock_screen.dart';
import 'package:bloomwell/features/cycle_care/presentation/cycle_care_screen.dart';
import 'package:bloomwell/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeHomeCycleRepo implements ICycleCareRepository {
  @override
  Future<CycleTrackingStatus> getCycleTrackingStatus() async {
    return const CycleTrackingStatus(cycleTrackingEnabled: true);
  }

  @override
  Future<CycleTrackingStatus> updateCycleTracking({
    required bool enabled,
    bool deleteData = false,
  }) async {
    return CycleTrackingStatus(cycleTrackingEnabled: enabled);
  }

  @override
  Future<({List<CyclePeriodEntry> items, String? nextCursor, bool hasMore})>
      getCycles({
    String? fromDate,
    String? toDate,
    String? cursor,
    int limit = 20,
  }) async {
    return (items: <CyclePeriodEntry>[], nextCursor: null, hasMore: false);
  }

  @override
  Future<CyclePeriodEntry> createPeriod({
    required String clientId,
    required String periodStart,
    String? periodEnd,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CyclePeriodEntry> updatePeriod({
    required String id,
    String? periodStart,
    String? periodEnd,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deletePeriod(String id) async {}

  @override
  Future<({List<CycleSymptomEntry> items, String? nextCursor, bool hasMore})>
      getSymptoms({
    String? fromDate,
    String? toDate,
    String? cursor,
    int limit = 50,
  }) async {
    return (items: <CycleSymptomEntry>[], nextCursor: null, hasMore: false);
  }

  @override
  Future<CycleSymptomEntry> createSymptom({
    required String clientId,
    required String date,
    required CycleSymptomType symptomType,
    required int severity,
    String? customLabel,
    String? notes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CycleSymptomEntry> updateSymptom({
    required String id,
    String? date,
    CycleSymptomType? symptomType,
    int? severity,
    String? customLabel,
    String? notes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteSymptom(String id) async {}

  @override
  Future<CycleHistoryInsight> getCycleHistoryInsight() async {
    return const CycleHistoryInsight(
      estimate: CycleEstimate(status: CycleEstimateStatus.notEnoughData),
      recentCycles: [],
    );
  }
}

class FakeBiometrics implements BiometricService {
  @override
  Future<bool> isDeviceSupported() async => false;

  @override
  Future<bool> canCheckBiometrics() async => false;

  @override
  Future<BiometricAuthResult> authenticate(
          {required String localizedReason}) async =>
      BiometricAuthResult.notAvailable;
}

class FakePlatformChannel extends SecurityPlatformChannel {
  @override
  Future<void> setFlagSecure(bool enabled) async {}
}

Widget createHomeApp({required FakeHomeCycleRepo repo}) {
  return ProviderScope(
    overrides: [
      cycleCareRepositoryProvider.overrideWithValue(repo),
      biometricServiceProvider.overrideWithValue(FakeBiometrics()),
      securityPlatformChannelProvider.overrideWithValue(FakePlatformChannel()),
    ],
    child: MaterialApp.router(
      routerConfig: appRouter,
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
    ),
  );
}

void main() {
  late FakeHomeCycleRepo repo;

  setUp(() {
    repo = FakeHomeCycleRepo();
    routerRefreshNotifier.updateLock(false);
  });

  testWidgets(
      'Home screen preview card renders generic copy with zero sensitive predictions',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createHomeApp(repo: repo));
    await tester.pumpAndSettle();

    final previewCard = find.byKey(const Key('home_cycle_care_preview_card'));
    expect(previewCard, findsOneWidget);

    // Assert strictly generic copy
    expect(find.text('Check in with your body'), findsOneWidget);
    expect(find.text('Notice your energy and rhythm today'), findsOneWidget);
    expect(find.text('Open CycleCare'), findsOneWidget);

    // Assert zero sensitive dates or predictions
    expect(find.textContaining('expected'), findsNothing);
    expect(find.textContaining('next period'), findsNothing);
    expect(find.textContaining('phase'), findsNothing);
    expect(find.textContaining('luteal'), findsNothing);
    expect(find.textContaining('follicular'), findsNothing);
    expect(find.textContaining('ovulation'), findsNothing);
    expect(find.textContaining('fertile'), findsNothing);
    expect(find.textContaining('pregnancy'), findsNothing);
  });

  testWidgets('Tapping home preview card navigates to CycleCareScreen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createHomeApp(repo: repo));
    await tester.pumpAndSettle();

    final previewCard = find.byKey(const Key('home_cycle_care_preview_card'));
    await tester.ensureVisible(previewCard);
    await tester.tap(previewCard);
    await tester.pumpAndSettle();

    // Verify CycleCareScreen is rendered
    expect(find.byType(CycleCareScreen), findsOneWidget);
  });

  testWidgets('AppLock protects CycleCare when device/app is locked',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createHomeApp(repo: repo));
    await tester.pumpAndSettle();

    // Lock the app
    routerRefreshNotifier.updateLock(true);
    await tester.pumpAndSettle();

    // Verify redirected to Lock Screen
    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.text('BloomWell Locked'), findsOneWidget);
    expect(find.byType(CycleCareScreen), findsNothing);
  });
}
