import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exceptions.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/domain/entities/auth_state.dart';
import '../data/cycle_care_repository.dart';
import '../domain/entities/cycle_estimate.dart';
import '../domain/entities/cycle_period_entry.dart';
import '../domain/entities/cycle_symptom_entry.dart';
import '../domain/entities/cycle_tracking_status.dart';

/// Calendar display mode for accessibility.
enum CalendarViewMode {
  grid,
  list,
}

/// In-memory state for CycleCare.
/// All sensitive cycle and symptom entries are strictly kept in-memory
/// and wiped completely upon logout or when cycle tracking is disabled.
class CycleCareState {
  final CycleTrackingStatus? trackingStatus;
  final bool isLoading;
  final bool isActionLoading;
  final bool isLoadingHistory;
  final String? errorMessage;
  final DateTime selectedMonth;
  final DateTime? selectedDate;
  final CalendarViewMode calendarViewMode;
  final List<CyclePeriodEntry> monthCycles;
  final List<CycleSymptomEntry> monthSymptoms;
  final List<CyclePeriodEntry> historyCycles;
  final String? historyCursor;
  final bool hasMoreHistory;
  final CycleEstimate? estimate;
  final List<CyclePeriodEntry> recentCycles;

  const CycleCareState({
    this.trackingStatus,
    this.isLoading = false,
    this.isActionLoading = false,
    this.isLoadingHistory = false,
    this.errorMessage,
    required this.selectedMonth,
    this.selectedDate,
    this.calendarViewMode = CalendarViewMode.grid,
    this.monthCycles = const [],
    this.monthSymptoms = const [],
    this.historyCycles = const [],
    this.historyCursor,
    this.hasMoreHistory = false,
    this.estimate,
    this.recentCycles = const [],
  });

  factory CycleCareState.initial() {
    final now = DateTime.now();
    return CycleCareState(
      trackingStatus: null,
      isLoading: false,
      isActionLoading: false,
      isLoadingHistory: false,
      errorMessage: null,
      selectedMonth: DateTime(now.year, now.month, 1),
      selectedDate: DateTime(now.year, now.month, now.day),
      calendarViewMode: CalendarViewMode.grid,
      monthCycles: const [],
      monthSymptoms: const [],
      historyCycles: const [],
      historyCursor: null,
      hasMoreHistory: false,
      estimate: null,
      recentCycles: const [],
    );
  }

  bool get isTrackingEnabled => trackingStatus?.cycleTrackingEnabled ?? false;

  CycleCareState copyWith({
    CycleTrackingStatus? trackingStatus,
    bool? isLoading,
    bool? isActionLoading,
    bool? isLoadingHistory,
    String? errorMessage,
    bool clearErrorMessage = false,
    DateTime? selectedMonth,
    DateTime? selectedDate,
    bool clearSelectedDate = false,
    CalendarViewMode? calendarViewMode,
    List<CyclePeriodEntry>? monthCycles,
    List<CycleSymptomEntry>? monthSymptoms,
    List<CyclePeriodEntry>? historyCycles,
    String? historyCursor,
    bool clearHistoryCursor = false,
    bool? hasMoreHistory,
    CycleEstimate? estimate,
    bool clearEstimate = false,
    List<CyclePeriodEntry>? recentCycles,
  }) {
    return CycleCareState(
      trackingStatus: trackingStatus ?? this.trackingStatus,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedDate:
          clearSelectedDate ? null : (selectedDate ?? this.selectedDate),
      calendarViewMode: calendarViewMode ?? this.calendarViewMode,
      monthCycles: monthCycles ?? this.monthCycles,
      monthSymptoms: monthSymptoms ?? this.monthSymptoms,
      historyCycles: historyCycles ?? this.historyCycles,
      historyCursor:
          clearHistoryCursor ? null : (historyCursor ?? this.historyCursor),
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
      estimate: clearEstimate ? null : (estimate ?? this.estimate),
      recentCycles: recentCycles ?? this.recentCycles,
    );
  }
}

/// Provider for CycleCareRepository.
final cycleCareRepositoryProvider = Provider<ICycleCareRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CycleCareRepository(apiClient: apiClient);
});

/// Riverpod Notifier for managing CycleCare state with strict in-memory isolation.
class CycleCareNotifier extends Notifier<CycleCareState> {
  late ICycleCareRepository _repository;

  @override
  CycleCareState build() {
    _repository = ref.watch(cycleCareRepositoryProvider);

    // Strict privacy boundary: when authentication ends, wipe all sensitive health data immediately.
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (!next.isAuthenticated) {
        clearAllData();
      }
    });

    return CycleCareState.initial();
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Initial load: checks user opt-in status. If enabled, loads month data, insight, and history.
  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final status = await _repository.getCycleTrackingStatus();
      if (!status.cycleTrackingEnabled) {
        state = CycleCareState.initial().copyWith(
          trackingStatus: status,
          isLoading: false,
        );
        return;
      }

      state = state.copyWith(trackingStatus: status);
      await _fetchMonthData(state.selectedMonth);
      await _fetchInsight();
      await _fetchInitialHistory();
      state = state.copyWith(isLoading: false);
    } on CycleTrackingDisabledException {
      state = CycleCareState.initial().copyWith(
        trackingStatus: const CycleTrackingStatus(cycleTrackingEnabled: false),
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load cycle information. Please try again.',
      );
    }
  }

  /// Fetches periods and symptoms for a selected month range (with a ±7 day boundary buffer).
  Future<void> _fetchMonthData(DateTime month) async {
    final startBuffer = DateTime(month.year, month.month, 1).subtract(
      const Duration(days: 7),
    );
    final endBuffer = DateTime(month.year, month.month + 1, 0).add(
      const Duration(days: 7),
    );

    final fromDate = _formatDate(startBuffer);
    final toDate = _formatDate(endBuffer);

    try {
      final cyclesResult = await _repository.getCycles(
        fromDate: fromDate,
        toDate: toDate,
        limit: 50,
      );
      final symptomsResult = await _repository.getSymptoms(
        fromDate: fromDate,
        toDate: toDate,
        limit: 100,
      );

      state = state.copyWith(
        monthCycles: cyclesResult.items,
        monthSymptoms: symptomsResult.items,
      );
    } on CycleTrackingDisabledException {
      clearAllData();
      state = state.copyWith(
        trackingStatus: const CycleTrackingStatus(cycleTrackingEnabled: false),
      );
    }
  }

  /// Fetches estimates and recent cycle summary.
  Future<void> _fetchInsight() async {
    try {
      final insight = await _repository.getCycleHistoryInsight();
      state = state.copyWith(
        estimate: insight.estimate,
        recentCycles: insight.recentCycles,
      );
    } catch (_) {
      // Non-blocking: insight failures do not break the main calendar
    }
  }

  /// Fetches initial history page.
  Future<void> _fetchInitialHistory() async {
    try {
      final result = await _repository.getCycles(limit: 10);
      state = state.copyWith(
        historyCycles: result.items,
        historyCursor: result.nextCursor,
        hasMoreHistory: result.hasMore,
      );
    } catch (_) {
      // Non-blocking
    }
  }

  /// Loads subsequent history pages using cursor pagination.
  Future<void> loadMoreHistory() async {
    if (!state.hasMoreHistory || state.isLoadingHistory) return;
    state = state.copyWith(isLoadingHistory: true);
    try {
      final result = await _repository.getCycles(
        cursor: state.historyCursor,
        limit: 10,
      );
      state = state.copyWith(
        historyCycles: [...state.historyCycles, ...result.items],
        historyCursor: result.nextCursor,
        hasMoreHistory: result.hasMore,
        isLoadingHistory: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingHistory: false);
    }
  }

  /// Enables cycle tracking after explicit opt-in.
  Future<bool> enableTracking() async {
    state = state.copyWith(isActionLoading: true, clearErrorMessage: true);
    try {
      final status = await _repository.updateCycleTracking(enabled: true);
      state = state.copyWith(
        trackingStatus: status,
        isActionLoading: false,
      );
      await loadInitial();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Failed to enable tracking. Please try again.',
      );
      return false;
    }
  }

  /// Disables cycle tracking, optionally purging all data on server.
  /// Wipes all sensitive data from memory immediately.
  Future<bool> disableTracking({bool deleteData = false}) async {
    state = state.copyWith(isActionLoading: true, clearErrorMessage: true);
    try {
      final status = await _repository.updateCycleTracking(
        enabled: false,
        deleteData: deleteData,
      );
      clearAllData();
      state = state.copyWith(trackingStatus: status);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Failed to update tracking settings. Please try again.',
      );
      return false;
    }
  }

  /// Changes the visible month and loads month-specific entries.
  Future<void> changeMonth(DateTime newMonth) async {
    final normalized = DateTime(newMonth.year, newMonth.month, 1);
    state = state.copyWith(selectedMonth: normalized);
    if (state.isTrackingEnabled) {
      await _fetchMonthData(normalized);
    }
  }

  /// Selects a date for the day details sheet.
  void selectDate(DateTime? date) {
    state = state.copyWith(
      selectedDate: date,
      clearSelectedDate: date == null,
    );
  }

  /// Toggles between month grid and accessible list view.
  void toggleViewMode() {
    final next = state.calendarViewMode == CalendarViewMode.grid
        ? CalendarViewMode.list
        : CalendarViewMode.grid;
    state = state.copyWith(calendarViewMode: next);
  }

  /// Logs or creates a period entry with client_id idempotency.
  Future<bool> logPeriod({
    required String clientId,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isActionLoading: true, clearErrorMessage: true);
    try {
      final periodStartStr = _formatDate(startDate);
      final periodEndStr = endDate != null ? _formatDate(endDate) : null;

      await _repository.createPeriod(
        clientId: clientId,
        periodStart: periodStartStr,
        periodEnd: periodEndStr,
      );

      await _fetchMonthData(state.selectedMonth);
      await _fetchInsight();
      await _fetchInitialHistory();
      state = state.copyWith(isActionLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Unable to save period entry. Please try again.',
      );
      return false;
    }
  }

  /// Updates an existing period entry.
  Future<bool> updatePeriod({
    required String id,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isActionLoading: true, clearErrorMessage: true);
    try {
      final periodStartStr = startDate != null ? _formatDate(startDate) : null;
      final periodEndStr = endDate != null ? _formatDate(endDate) : null;

      await _repository.updatePeriod(
        id: id,
        periodStart: periodStartStr,
        periodEnd: periodEndStr,
      );

      await _fetchMonthData(state.selectedMonth);
      await _fetchInsight();
      await _fetchInitialHistory();
      state = state.copyWith(isActionLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Unable to update period entry. Please try again.',
      );
      return false;
    }
  }

  /// Deletes a period entry.
  Future<bool> deletePeriod(String id) async {
    state = state.copyWith(isActionLoading: true, clearErrorMessage: true);
    try {
      await _repository.deletePeriod(id);
      await _fetchMonthData(state.selectedMonth);
      await _fetchInsight();
      await _fetchInitialHistory();
      state = state.copyWith(isActionLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Unable to remove period entry. Please try again.',
      );
      return false;
    }
  }

  /// Logs a symptom entry with client_id idempotency.
  Future<bool> logSymptom({
    required String clientId,
    required DateTime date,
    required CycleSymptomType symptomType,
    required int severity,
    String? customLabel,
    String? notes,
  }) async {
    state = state.copyWith(isActionLoading: true, clearErrorMessage: true);
    try {
      final dateStr = _formatDate(date);
      await _repository.createSymptom(
        clientId: clientId,
        date: dateStr,
        symptomType: symptomType,
        severity: severity,
        customLabel: customLabel,
        notes: notes,
      );

      await _fetchMonthData(state.selectedMonth);
      state = state.copyWith(isActionLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Unable to save symptom entry. Please try again.',
      );
      return false;
    }
  }

  /// Deletes a symptom entry.
  Future<bool> deleteSymptom(String id) async {
    state = state.copyWith(isActionLoading: true, clearErrorMessage: true);
    try {
      await _repository.deleteSymptom(id);
      state = state.copyWith(
        monthSymptoms: state.monthSymptoms.where((s) => s.id != id).toList(),
        isActionLoading: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Unable to remove symptom entry. Please try again.',
      );
      return false;
    }
  }

  /// Clears any transient error message.
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearErrorMessage: true);
    }
  }

  /// Wipes all sensitive health data from memory.
  void clearAllData() {
    state = CycleCareState.initial();
  }
}

/// Main CycleCare state provider.
final cycleCareNotifierProvider =
    NotifierProvider<CycleCareNotifier, CycleCareState>(CycleCareNotifier.new);
