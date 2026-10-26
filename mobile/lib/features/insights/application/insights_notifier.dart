import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exceptions.dart';
import '../../app_lock/application/app_lock_notifier.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/domain/entities/auth_state.dart';
import '../data/insights_repository.dart';
import '../domain/entities/exam_context_insights.dart';
import '../domain/entities/weekly_insights.dart';

/// State for personal wellness observations.
class InsightsState {
  const InsightsState({
    this.weeklyInsights,
    this.examInsights,
    this.isLoading = false,
    this.errorMessage,
  });

  final WeeklyInsights? weeklyInsights;
  final ExamContextInsights? examInsights;
  final bool isLoading;
  final String? errorMessage;

  InsightsState copyWith({
    WeeklyInsights? weeklyInsights,
    bool clearWeekly = false,
    ExamContextInsights? examInsights,
    bool clearExam = false,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return InsightsState(
      weeklyInsights:
          clearWeekly ? null : (weeklyInsights ?? this.weeklyInsights),
      examInsights: clearExam ? null : (examInsights ?? this.examInsights),
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Provider for IInsightsRepository.
final insightsRepositoryProvider = Provider<IInsightsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return InsightsRepository(apiClient: apiClient);
});

/// Riverpod notifier managing personal observations with strict in-memory lifecycle.
class InsightsNotifier extends Notifier<InsightsState> {
  late IInsightsRepository _repository;

  @override
  InsightsState build() {
    _repository = ref.watch(insightsRepositoryProvider);

    // Strict privacy boundary: wipe state immediately upon unauthenticated or session expiry
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (!next.isAuthenticated) {
        clearAllData();
      }
    });

    return const InsightsState();
  }

  /// Wipes all in-memory observation state.
  void clearAllData() {
    state = const InsightsState();
  }

  /// Loads both weekly and exam-context insights concurrently.
  Future<void> loadAllInsights(
      {String? weekStart, bool refresh = false}) async {
    // If locked, privacy boundary prevents fetching
    if (ref.read(appLockNotifierProvider).isLocked) {
      return;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final results = await Future.wait([
        _repository.getWeeklyInsights(weekStart: weekStart),
        _repository.getExamContextInsights(),
      ]);

      state = state.copyWith(
        weeklyInsights: results[0] as WeeklyInsights,
        examInsights: results[1] as ExamContextInsights,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load personal observations. Please try again.',
      );
    }
  }

  /// Loads only weekly insights.
  Future<void> loadWeeklyInsights({String? weekStart}) async {
    if (ref.read(appLockNotifierProvider).isLocked) {
      return;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final weekly = await _repository.getWeeklyInsights(weekStart: weekStart);
      state = state.copyWith(weeklyInsights: weekly, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load weekly observations.',
      );
    }
  }

  /// Loads only exam-context insights.
  Future<void> loadExamContextInsights() async {
    if (ref.read(appLockNotifierProvider).isLocked) {
      return;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final exam = await _repository.getExamContextInsights();
      state = state.copyWith(examInsights: exam, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load exam observations.',
      );
    }
  }
}

final insightsNotifierProvider =
    NotifierProvider<InsightsNotifier, InsightsState>(
  InsightsNotifier.new,
);
