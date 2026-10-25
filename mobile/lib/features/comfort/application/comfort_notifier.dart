import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exceptions.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/domain/entities/auth_state.dart';
import '../../self_care/application/self_care_notifier.dart';
import '../../self_care/domain/entities/activity_suggestion.dart';
import '../data/comfort_repository.dart';
import '../domain/entities/comfort_need.dart';
import '../domain/entities/comfort_plan_item.dart';

/// Available duration tiers for deterministic "Show me something else" cycling.
const List<int> comfortDurationTiers = [5, 10, 15, 2];

/// State for Comfort Mode: low-stimulation suggestions and personal comfort plan.
class ComfortState {
  final ComfortNeed selectedNeed;
  final List<ActivitySuggestion> suggestions;
  final bool isLoadingSuggestions;
  final List<ComfortPlanItem> comfortPlan;
  final bool isLoadingPlan;
  final bool isActionLoading;
  final int durationTierIndex;
  final String? errorMessage;

  const ComfortState({
    this.selectedNeed = ComfortNeed.calmDown,
    this.suggestions = const [],
    this.isLoadingSuggestions = false,
    this.comfortPlan = const [],
    this.isLoadingPlan = false,
    this.isActionLoading = false,
    this.durationTierIndex = 0,
    this.errorMessage,
  });

  int get currentMaxDuration => comfortDurationTiers[durationTierIndex];

  ComfortState copyWith({
    ComfortNeed? selectedNeed,
    List<ActivitySuggestion>? suggestions,
    bool? isLoadingSuggestions,
    List<ComfortPlanItem>? comfortPlan,
    bool? isLoadingPlan,
    bool? isActionLoading,
    int? durationTierIndex,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ComfortState(
      selectedNeed: selectedNeed ?? this.selectedNeed,
      suggestions: suggestions ?? this.suggestions,
      isLoadingSuggestions: isLoadingSuggestions ?? this.isLoadingSuggestions,
      comfortPlan: comfortPlan ?? this.comfortPlan,
      isLoadingPlan: isLoadingPlan ?? this.isLoadingPlan,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      durationTierIndex: durationTierIndex ?? this.durationTierIndex,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Provider for IComfortRepository.
final comfortRepositoryProvider = Provider<IComfortRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ComfortRepository(apiClient: apiClient);
});

/// Riverpod Notifier managing Comfort Mode.
class ComfortNotifier extends Notifier<ComfortState> {
  late IComfortRepository _comfortRepo;

  @override
  ComfortState build() {
    _comfortRepo = ref.watch(comfortRepositoryProvider);

    // Privacy boundary: wipe comfort plan and suggestions immediately on logout
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (!next.isAuthenticated) {
        clearAllUserData();
      }
    });

    return const ComfortState();
  }

  /// Initial load: fetch suggestions for the default need and load the comfort plan.
  Future<void> loadInitial() async {
    await Future.wait([
      loadSuggestions(state.selectedNeed),
      loadComfortPlan(),
    ]);
  }

  /// Selects a need and fetches suggestions matching it.
  Future<void> selectNeed(ComfortNeed need) async {
    state = state.copyWith(
      selectedNeed: need,
      durationTierIndex: 0,
    );
    await loadSuggestions(need);
  }

  /// Fetches suggestions for a given need and current duration tier.
  Future<void> loadSuggestions(ComfortNeed need) async {
    final selfCareRepo = ref.read(selfCareRepositoryProvider);
    state = state.copyWith(isLoadingSuggestions: true, clearErrorMessage: true);
    try {
      final items = await selfCareRepo.getSuggestions(
        need: need.apiValue,
        maxDuration: state.currentMaxDuration,
      );
      state = state.copyWith(
        suggestions: items.take(5).toList(),
        isLoadingSuggestions: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoadingSuggestions: false,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingSuggestions: false,
        errorMessage: 'Unable to load comfort suggestions.',
      );
    }
  }

  /// "Show me something else": advances duration tier deterministically and re-queries.
  /// Never shuffles randomly on the client!
  Future<void> showSomethingElse() async {
    final nextTierIndex =
        (state.durationTierIndex + 1) % comfortDurationTiers.length;
    state = state.copyWith(durationTierIndex: nextTierIndex);
    await loadSuggestions(state.selectedNeed);
  }

  /// Loads the user's saved comfort plan.
  Future<void> loadComfortPlan() async {
    state = state.copyWith(isLoadingPlan: true, clearErrorMessage: true);
    try {
      final items = await _comfortRepo.getComfortPlan();
      state = state.copyWith(
        comfortPlan: items,
        isLoadingPlan: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingPlan: false);
    }
  }

  /// Adds an activity to the comfort plan.
  Future<bool> addToPlan(String activityId) async {
    state = state.copyWith(isActionLoading: true, clearErrorMessage: true);
    try {
      final newItem =
          await _comfortRepo.addToComfortPlan(activityId: activityId);
      state = state.copyWith(
        comfortPlan: [...state.comfortPlan, newItem],
        isActionLoading: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Failed to add activity to comfort plan.',
      );
      return false;
    }
  }

  /// Removes an item from the comfort plan.
  Future<bool> removeFromPlan(String itemId) async {
    state = state.copyWith(isActionLoading: true, clearErrorMessage: true);
    try {
      await _comfortRepo.removeFromComfortPlan(itemId);
      state = state.copyWith(
        comfortPlan: state.comfortPlan.where((i) => i.id != itemId).toList(),
        isActionLoading: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Failed to remove item from comfort plan.',
      );
      return false;
    }
  }

  /// Reorders comfort plan items.
  Future<bool> reorderPlan(int oldIndex, int newIndex) async {
    if (oldIndex < 0 ||
        oldIndex >= state.comfortPlan.length ||
        newIndex < 0 ||
        newIndex >= state.comfortPlan.length) {
      return false;
    }

    final updated = List<ComfortPlanItem>.from(state.comfortPlan);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);

    state = state.copyWith(comfortPlan: updated);

    try {
      final itemIds = updated.map((i) => i.id).toList();
      await _comfortRepo.reorderComfortPlan(itemIds);
      return true;
    } catch (_) {
      // Revert on failure
      await loadComfortPlan();
      return false;
    }
  }

  void clearAllUserData() {
    state = const ComfortState();
  }
}

/// Provider for ComfortNotifier.
final comfortNotifierProvider =
    NotifierProvider<ComfortNotifier, ComfortState>(ComfortNotifier.new);
