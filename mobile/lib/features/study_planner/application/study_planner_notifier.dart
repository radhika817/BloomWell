import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exceptions.dart';
import '../../app_lock/application/app_lock_notifier.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/domain/entities/auth_state.dart';
import '../../cycle_care/application/cycle_care_notifier.dart';
import '../data/study_planner_repository.dart';
import '../domain/entities/plan_item_status.dart';
import '../domain/entities/study_plan.dart';
import '../domain/entities/study_plan_item.dart';
import '../domain/entities/suggested_load.dart';
import '../domain/planner_date_utils.dart';
import 'planner_consent_notifier.dart';

/// State for weekly study planner interactions.
class StudyPlannerState {
  const StudyPlannerState({
    this.currentPlan,
    required this.selectedWeekStart,
    this.isLoading = false,
    this.isActionLoading = false,
    this.errorMessage,
    this.conflictPlanExists = false,
    this.cycleTrackingRequired = false,
    this.lastDeletedCount,
  });

  final StudyPlan? currentPlan;
  final DateTime selectedWeekStart;
  final bool isLoading;
  final bool isActionLoading;
  final String? errorMessage;
  final bool conflictPlanExists;
  final bool cycleTrackingRequired;
  final int? lastDeletedCount;

  bool get hasPlan => currentPlan != null;

  factory StudyPlannerState.initial() {
    return StudyPlannerState(
      selectedWeekStart: PlannerDateUtils.getMondayOfWeek(DateTime.now()),
    );
  }

  StudyPlannerState copyWith({
    StudyPlan? currentPlan,
    bool clearPlan = false,
    DateTime? selectedWeekStart,
    bool? isLoading,
    bool? isActionLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? conflictPlanExists,
    bool? cycleTrackingRequired,
    int? lastDeletedCount,
    bool clearLastDeletedCount = false,
  }) {
    return StudyPlannerState(
      currentPlan: clearPlan ? null : (currentPlan ?? this.currentPlan),
      selectedWeekStart: selectedWeekStart ?? this.selectedWeekStart,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      conflictPlanExists: conflictPlanExists ?? this.conflictPlanExists,
      cycleTrackingRequired:
          cycleTrackingRequired ?? this.cycleTrackingRequired,
      lastDeletedCount: clearLastDeletedCount
          ? null
          : (lastDeletedCount ?? this.lastDeletedCount),
    );
  }
}

/// Riverpod Notifier managing Study Planner state with strict in-memory lifecycle.
class StudyPlannerNotifier extends Notifier<StudyPlannerState> {
  late IStudyPlannerRepository _repository;

  @override
  StudyPlannerState build() {
    _repository = ref.watch(studyPlannerRepositoryProvider);

    // Strict privacy boundary: wipe state immediately upon unauthenticated or session expiry
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (!next.isAuthenticated) {
        clearAllData();
      }
    });

    // When cycle tracking or planner cycle consent is revoked, clear cycle-informed plans
    ref.listen<CycleCareState>(cycleCareNotifierProvider, (previous, next) {
      if (!next.isTrackingEnabled &&
          (state.currentPlan?.usesCycleData ?? false)) {
        clearPlanOnly();
      }
    });

    ref.listen<PlannerConsentState>(plannerConsentNotifierProvider,
        (previous, next) {
      if (!next.isConsentEnabled &&
          (state.currentPlan?.usesCycleData ?? false)) {
        clearPlanOnly();
      }
    });

    return StudyPlannerState.initial();
  }

  /// Wipes all in-memory planner state.
  void clearAllData() {
    state = StudyPlannerState.initial();
  }

  /// Clears only the active plan (e.g. after consent revocation).
  void clearPlanOnly() {
    state = state.copyWith(clearPlan: true);
  }

  /// Changes the currently selected week.
  void selectWeek(DateTime week) {
    final monday = PlannerDateUtils.getMondayOfWeek(week);
    state = state.copyWith(selectedWeekStart: monday, clearErrorMessage: true);
  }

  /// Loads the study plan for the selected or specified week.
  Future<void> loadPlan({DateTime? weekStart, bool refresh = false}) async {
    // If the app is locked, privacy boundary prevents fetching
    if (ref.read(appLockNotifierProvider).isLocked) {
      return;
    }

    final targetWeek = weekStart != null
        ? PlannerDateUtils.getMondayOfWeek(weekStart)
        : state.selectedWeekStart;

    state = state.copyWith(
      selectedWeekStart: targetWeek,
      isLoading: true,
      clearErrorMessage: true,
      conflictPlanExists: false,
    );

    try {
      final formattedWeek = PlannerDateUtils.formatDate(targetWeek);
      final plan = await _repository.getPlanByWeek(formattedWeek);
      state = state.copyWith(
        currentPlan: plan,
        clearPlan: plan == null,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load study plan. Please try again.',
      );
    }
  }

  /// Generates a study plan for the week.
  Future<bool> generatePlan({
    DateTime? weekStart,
    bool replace = false,
  }) async {
    final targetWeek = weekStart != null
        ? PlannerDateUtils.getMondayOfWeek(weekStart)
        : state.selectedWeekStart;

    state = state.copyWith(
      isActionLoading: true,
      clearErrorMessage: true,
      conflictPlanExists: false,
      cycleTrackingRequired: false,
    );

    try {
      final formatted = PlannerDateUtils.formatDate(targetWeek);
      final plan = await _repository.generatePlan(
        weekStart: formatted,
        replace: replace,
      );
      state = state.copyWith(
        currentPlan: plan,
        selectedWeekStart: targetWeek,
        isActionLoading: false,
      );
      return true;
    } on PlanExistsException {
      state = state.copyWith(
        isActionLoading: false,
        conflictPlanExists: true,
      );
      return false;
    } on CycleTrackingRequiredException {
      state = state.copyWith(
        isActionLoading: false,
        cycleTrackingRequired: true,
      );
      return false;
    } on ApiException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Failed to generate study plan. Please try again.',
      );
      return false;
    }
  }

  /// Deletes a study plan.
  Future<bool> deletePlan(String id) async {
    state = state.copyWith(isActionLoading: true, clearErrorMessage: true);
    try {
      await _repository.deletePlan(id);
      state = state.copyWith(
        clearPlan: true,
        isActionLoading: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Failed to delete study plan. Please try again.',
      );
      return false;
    }
  }

  /// Patches an individual day item (accept, edit, skip) and updates memory strictly on confirmation.
  Future<StudyPlanItem?> patchItem({
    required String itemId,
    required PlanItemStatus status,
    SuggestedLoad? suggestedLoad,
  }) async {
    state = state.copyWith(isActionLoading: true, clearErrorMessage: true);
    try {
      final updatedItem = await _repository.patchItem(
        itemId: itemId,
        status: status,
        suggestedLoad: suggestedLoad,
      );

      final current = state.currentPlan;
      if (current != null) {
        final updatedItems = current.items.map((item) {
          if (item.id == itemId) {
            return updatedItem;
          }
          return item;
        }).toList();
        state = state.copyWith(
          currentPlan: current.copyWith(items: updatedItems),
          isActionLoading: false,
        );
      } else {
        state = state.copyWith(isActionLoading: false);
      }
      return updatedItem;
    } on ApiException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return null;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Unable to update study day. Please try again.',
      );
      return null;
    }
  }
}

final studyPlannerNotifierProvider =
    NotifierProvider<StudyPlannerNotifier, StudyPlannerState>(
  StudyPlannerNotifier.new,
);
