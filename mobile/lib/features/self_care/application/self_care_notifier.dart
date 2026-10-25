import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exceptions.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/domain/entities/auth_state.dart';
import '../data/self_care_repository.dart';
import '../domain/entities/activity_category.dart';
import '../domain/entities/activity_completion_log.dart';
import '../domain/entities/activity_entry.dart';

/// State for the Self-Care Studio library and favorites.
class SelfCareState {
  final List<ActivityEntry> activities;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final ActivityCategory? selectedCategory;
  final int? maxDuration;
  final String? cursor;
  final bool hasMore;
  final Set<String> favorites;
  final Set<String> favoriteActionInProgress;

  const SelfCareState({
    this.activities = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.selectedCategory,
    this.maxDuration,
    this.cursor,
    this.hasMore = false,
    this.favorites = const {},
    this.favoriteActionInProgress = const {},
  });

  SelfCareState copyWith({
    List<ActivityEntry>? activities,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearErrorMessage = false,
    ActivityCategory? selectedCategory,
    bool clearSelectedCategory = false,
    int? maxDuration,
    bool clearMaxDuration = false,
    String? cursor,
    bool clearCursor = false,
    bool? hasMore,
    Set<String>? favorites,
    Set<String>? favoriteActionInProgress,
  }) {
    return SelfCareState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      selectedCategory: clearSelectedCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      maxDuration: clearMaxDuration ? null : (maxDuration ?? this.maxDuration),
      cursor: clearCursor ? null : (cursor ?? this.cursor),
      hasMore: hasMore ?? this.hasMore,
      favorites: favorites ?? this.favorites,
      favoriteActionInProgress:
          favoriteActionInProgress ?? this.favoriteActionInProgress,
    );
  }
}

/// Provider for ISelfCareRepository.
final selfCareRepositoryProvider = Provider<ISelfCareRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SelfCareRepository(apiClient: apiClient);
});

/// Riverpod Notifier for the Self-Care Studio library.
class SelfCareNotifier extends Notifier<SelfCareState> {
  late ISelfCareRepository _repository;

  @override
  SelfCareState build() {
    _repository = ref.watch(selfCareRepositoryProvider);

    // Privacy boundary: when user logs out or session expires, wipe all private user data
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (!next.isAuthenticated) {
        clearAllUserData();
      }
    });

    return const SelfCareState();
  }

  /// Initial load or filter refresh of activities.
  Future<void> loadActivities({bool refresh = false}) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final result = await _repository.getActivities(
        category: state.selectedCategory,
        maxDuration: state.maxDuration,
        limit: 20,
      );

      // Also refresh favorites
      final favResult = await _repository.getFavorites(limit: 100);
      final favIds = favResult.items.map((a) => a.id).toSet();

      final updatedActivities = result.items.map((a) {
        return a.copyWith(isFavorite: favIds.contains(a.id));
      }).toList();

      state = state.copyWith(
        activities: updatedActivities,
        favorites: favIds,
        cursor: result.nextCursor,
        hasMore: result.hasMore,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load activities. Please check connection.',
      );
    }
  }

  /// Cursor pagination infinite scroll.
  Future<void> loadMoreActivities() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _repository.getActivities(
        category: state.selectedCategory,
        maxDuration: state.maxDuration,
        cursor: state.cursor,
        limit: 20,
      );

      final updatedNewItems = result.items.map((a) {
        return a.copyWith(isFavorite: state.favorites.contains(a.id));
      }).toList();

      state = state.copyWith(
        activities: [...state.activities, ...updatedNewItems],
        cursor: result.nextCursor,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Sets category filter and re-fetches.
  Future<void> setCategoryFilter(ActivityCategory? category) async {
    if (state.selectedCategory == category) {
      state = state.copyWith(clearSelectedCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
    await loadActivities();
  }

  /// Sets duration filter ("up to 2 / 5 / 10 minutes") and re-fetches.
  Future<void> setDurationFilter(int? maxDuration) async {
    if (state.maxDuration == maxDuration) {
      state = state.copyWith(clearMaxDuration: true);
    } else {
      state = state.copyWith(maxDuration: maxDuration);
    }
    await loadActivities();
  }

  /// Toggles favorite status.
  /// Critical requirement: show the state only after the server confirms!
  Future<bool> toggleFavorite(String activityId) async {
    if (state.favoriteActionInProgress.contains(activityId)) return false;

    final currentlyFavorite = state.favorites.contains(activityId);
    final targetState = !currentlyFavorite;

    state = state.copyWith(
      favoriteActionInProgress: {...state.favoriteActionInProgress, activityId},
    );

    try {
      final serverConfirmedState = await _repository.setFavorite(
        activityId: activityId,
        isFavorite: targetState,
      );

      final newFavorites = Set<String>.from(state.favorites);
      if (serverConfirmedState) {
        newFavorites.add(activityId);
      } else {
        newFavorites.remove(activityId);
      }

      // Update in-memory activity cards only after server confirmation
      final updatedActivities = state.activities.map((a) {
        if (a.id == activityId) {
          return a.copyWith(isFavorite: serverConfirmedState);
        }
        return a;
      }).toList();

      final inProgress = Set<String>.from(state.favoriteActionInProgress)
        ..remove(activityId);

      state = state.copyWith(
        activities: updatedActivities,
        favorites: newFavorites,
        favoriteActionInProgress: inProgress,
      );
      return serverConfirmedState;
    } catch (e) {
      final inProgress = Set<String>.from(state.favoriteActionInProgress)
        ..remove(activityId);
      state = state.copyWith(
        favoriteActionInProgress: inProgress,
        errorMessage: 'Failed to update favorite. Please try again.',
      );
      return currentlyFavorite;
    }
  }

  /// Completes an activity with optional rating and client_id idempotency.
  Future<ActivityCompletionLog?> completeActivity({
    required String clientId,
    required String activityId,
    int? helpfulnessRating,
  }) async {
    try {
      return await _repository.completeActivity(
        clientId: clientId,
        activityId: activityId,
        helpfulnessRating: helpfulnessRating,
      );
    } catch (_) {
      return null;
    }
  }

  void clearAllUserData() {
    state = const SelfCareState();
  }
}

/// Provider for SelfCareNotifier.
final selfCareNotifierProvider =
    NotifierProvider<SelfCareNotifier, SelfCareState>(SelfCareNotifier.new);
