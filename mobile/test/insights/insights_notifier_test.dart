import 'package:bloomwell/core/api/api_exceptions.dart';
import 'package:bloomwell/features/auth/application/auth_notifier.dart';
import 'package:bloomwell/features/auth/domain/entities/auth_state.dart';
import 'package:bloomwell/features/insights/application/insights_notifier.dart';
import 'package:bloomwell/features/insights/data/insights_repository.dart';
import 'package:bloomwell/features/insights/domain/entities/exam_context_insights.dart';
import 'package:bloomwell/features/insights/domain/entities/insight_status.dart';
import 'package:bloomwell/features/insights/domain/entities/weekly_insights.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeInsightsRepository implements IInsightsRepository {
  WeeklyInsights? weeklyToReturn;
  ExamContextInsights? examToReturn;
  bool throwError = false;

  @override
  Future<WeeklyInsights> getWeeklyInsights({String? weekStart}) async {
    if (throwError) {
      throw const ServerException(message: 'Failed to fetch weekly insights');
    }
    return weeklyToReturn ??
        const WeeklyInsights(
          status: InsightStatus.notEnoughData,
          weekStart: '2026-10-19',
        );
  }

  @override
  Future<ExamContextInsights> getExamContextInsights() async {
    if (throwError) {
      throw const ServerException(message: 'Failed to fetch exam insights');
    }
    return examToReturn ??
        const ExamContextInsights(status: InsightStatus.notEnoughData);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InsightsNotifier Unit Tests', () {
    late _FakeInsightsRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = _FakeInsightsRepository();
      container = ProviderContainer(
        overrides: [
          insightsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is empty', () {
      final state = container.read(insightsNotifierProvider);
      expect(state.weeklyInsights, isNull);
      expect(state.examInsights, isNull);
      expect(state.isLoading, isFalse);
    });

    test('loadAllInsights populates both weekly and exam observations',
        () async {
      fakeRepo.weeklyToReturn = const WeeklyInsights(
        status: InsightStatus.sufficientData,
        weekStart: '2026-10-19',
        metrics: {
          'mood': WeeklyMetricComparison(
            weekAverage: 4.0,
            baselineAverage: 3.0,
            diff: 1.0,
            code: 'HIGHER_THAN_USUAL',
          ),
        },
      );
      fakeRepo.examToReturn = const ExamContextInsights(
        status: InsightStatus.sufficientData,
        qualifyingEventsCount: 2,
        stress: ExamMetricComparison(
          preEventAverage: 4.0,
          baselineAverage: 2.0,
          diff: 2.0,
          code: 'STRESS_HIGHER_BEFORE_EVENTS',
        ),
      );

      final notifier = container.read(insightsNotifierProvider.notifier);
      await notifier.loadAllInsights();

      final state = container.read(insightsNotifierProvider);
      expect(state.weeklyInsights?.hasSufficientData, isTrue);
      expect(state.examInsights?.hasSufficientData, isTrue);
      expect(state.weeklyInsights?.metrics?['mood']?.code,
          equals('HIGHER_THAN_USUAL'));
      expect(state.examInsights?.stress?.code,
          equals('STRESS_HIGHER_BEFORE_EVENTS'));
    });

    test('loadAllInsights sets error message on exception', () async {
      fakeRepo.throwError = true;

      final notifier = container.read(insightsNotifierProvider.notifier);
      await notifier.loadAllInsights();

      final state = container.read(insightsNotifierProvider);
      expect(state.errorMessage, contains('Failed to fetch'));
      expect(state.isLoading, isFalse);
    });

    test('In-memory isolation: clearAllData wipes observations', () async {
      fakeRepo.weeklyToReturn = const WeeklyInsights(
        status: InsightStatus.sufficientData,
        weekStart: '2026-10-19',
      );
      final notifier = container.read(insightsNotifierProvider.notifier);
      await notifier.loadAllInsights();
      expect(
          container.read(insightsNotifierProvider).weeklyInsights, isNotNull);

      notifier.clearAllData();
      final state = container.read(insightsNotifierProvider);
      expect(state.weeklyInsights, isNull);
      expect(state.examInsights, isNull);
    });

    test('Privacy boundary: Auth unauthenticated clears all insights in memory',
        () async {
      fakeRepo.weeklyToReturn = const WeeklyInsights(
        status: InsightStatus.sufficientData,
        weekStart: '2026-10-19',
      );
      final notifier = container.read(insightsNotifierProvider.notifier);
      await notifier.loadAllInsights();
      expect(
          container.read(insightsNotifierProvider).weeklyInsights, isNotNull);

      container.read(authNotifierProvider.notifier).state =
          const AuthState.unauthenticated();

      final state = container.read(insightsNotifierProvider);
      expect(state.weeklyInsights, isNull);
      expect(state.examInsights, isNull);
    });
  });
}
