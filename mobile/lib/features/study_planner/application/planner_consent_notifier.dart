import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exceptions.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/domain/entities/auth_state.dart';
import '../../cycle_care/application/cycle_care_notifier.dart';
import '../data/study_planner_repository.dart';
import '../domain/entities/planner_cycle_consent.dart';

/// State for planner cycle consent operations.
class PlannerConsentState {
  const PlannerConsentState({
    this.consent,
    this.isLoading = false,
    this.isActionLoading = false,
    this.errorMessage,
    this.cycleTrackingRequired = false,
  });

  final PlannerCycleConsent? consent;
  final bool isLoading;
  final bool isActionLoading;
  final String? errorMessage;
  final bool cycleTrackingRequired;

  bool get isConsentEnabled => consent?.enabled ?? false;

  PlannerConsentState copyWith({
    PlannerCycleConsent? consent,
    bool clearConsent = false,
    bool? isLoading,
    bool? isActionLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? cycleTrackingRequired,
  }) {
    return PlannerConsentState(
      consent: clearConsent ? null : (consent ?? this.consent),
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      cycleTrackingRequired:
          cycleTrackingRequired ?? this.cycleTrackingRequired,
    );
  }
}

/// Provider for IStudyPlannerRepository.
final studyPlannerRepositoryProvider = Provider<IStudyPlannerRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StudyPlannerRepository(apiClient: apiClient);
});

/// Riverpod notifier managing planner cycle consent with strict in-memory lifecycle.
class PlannerConsentNotifier extends Notifier<PlannerConsentState> {
  late IStudyPlannerRepository _repository;

  @override
  PlannerConsentState build() {
    _repository = ref.watch(studyPlannerRepositoryProvider);

    // Strict privacy boundary: wipe state immediately upon unauthenticated or session expiry
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (!next.isAuthenticated) {
        clearAllData();
      }
    });

    // When cycle tracking is disabled, reset consent state in memory
    ref.listen<CycleCareState>(cycleCareNotifierProvider, (previous, next) {
      if (!next.isTrackingEnabled && state.isConsentEnabled) {
        state = state.copyWith(
          consent: const PlannerCycleConsent(enabled: false),
        );
      }
    });

    return const PlannerConsentState();
  }

  /// Wipes all in-memory consent state.
  void clearAllData() {
    state = const PlannerConsentState();
  }

  /// Loads current planner cycle consent from server.
  Future<void> loadConsent() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final consent = await _repository.getPlannerCycleConsent();
      state = state.copyWith(consent: consent, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load study planner consent settings.',
      );
    }
  }

  /// Updates planner cycle consent (opt-in or revocation).
  Future<int?> updateConsent({required bool enabled}) async {
    state = state.copyWith(
      isActionLoading: true,
      clearErrorMessage: true,
      cycleTrackingRequired: false,
    );
    try {
      final updated =
          await _repository.updatePlannerCycleConsent(enabled: enabled);
      state = state.copyWith(
        consent: updated,
        isActionLoading: false,
      );
      return updated.deletedCyclePlansCount;
    } on CycleTrackingRequiredException {
      state = state.copyWith(
        isActionLoading: false,
        cycleTrackingRequired: true,
      );
      return null;
    } on ApiException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return null;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Failed to update planner settings. Please try again.',
      );
      return null;
    }
  }
}

final plannerConsentNotifierProvider =
    NotifierProvider<PlannerConsentNotifier, PlannerConsentState>(
  PlannerConsentNotifier.new,
);
