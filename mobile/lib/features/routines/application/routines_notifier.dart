import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exceptions.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/domain/entities/auth_state.dart';
import '../data/routines_repository.dart';
import '../domain/entities/routine.dart';
import '../domain/entities/routine_item.dart';

/// State for routines and their items.
class RoutinesState {
  final List<Routine> routines;
  final bool isLoading;
  final bool isActionLoading;
  final String? errorMessage;

  const RoutinesState({
    this.routines = const [],
    this.isLoading = false,
    this.isActionLoading = false,
    this.errorMessage,
  });

  RoutinesState copyWith({
    List<Routine>? routines,
    bool? isLoading,
    bool? isActionLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return RoutinesState(
      routines: routines ?? this.routines,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Provider for IRoutinesRepository.
final routinesRepositoryProvider = Provider<IRoutinesRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RoutinesRepository(apiClient: apiClient);
});

/// Riverpod Notifier for managing routines and routine items.
class RoutinesNotifier extends Notifier<RoutinesState> {
  late IRoutinesRepository _repository;

  @override
  RoutinesState build() {
    _repository = ref.watch(routinesRepositoryProvider);

    // Privacy boundary: wipe routines immediately upon session expiry/logout
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (!next.isAuthenticated) {
        clearAllUserData();
      }
    });

    return const RoutinesState();
  }

  /// Loads all routines for the authenticated user.
  Future<void> loadRoutines() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final items = await _repository.getRoutines();
      state = state.copyWith(
        routines: items,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load routines.',
      );
    }
  }

  /// Creates a routine, respecting the maximum limit of 20 routines.
  Future<bool> createRoutine({
    required String title,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (state.routines.length >= 20) {
      state = state.copyWith(
        errorMessage: 'You have reached the maximum limit of 20 routines.',
      );
      return false;
    }

    state = state.copyWith(isActionLoading: true, clearErrorMessage: true);
    try {
      final created = await _repository.createRoutine(
        title: title,
        startDate: startDate,
        endDate: endDate,
      );
      state = state.copyWith(
        routines: [...state.routines, created],
        isActionLoading: false,
      );
      return true;
    } on RoutineLimitExceededException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return false;
    } on ApiException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Failed to create routine. Please try again.',
      );
      return false;
    }
  }

  /// Updates routine details.
  Future<bool> updateRoutine({
    required String id,
    String? title,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
  }) async {
    state = state.copyWith(isActionLoading: true, clearErrorMessage: true);
    try {
      final updated = await _repository.updateRoutine(
        id: id,
        title: title,
        startDate: startDate,
        clearStartDate: clearStartDate,
        endDate: endDate,
        clearEndDate: clearEndDate,
      );

      final nextRoutines = state.routines.map((r) {
        return r.id == id ? updated : r;
      }).toList();

      state = state.copyWith(
        routines: nextRoutines,
        isActionLoading: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Failed to update routine.',
      );
      return false;
    }
  }

  /// Deletes a routine after user confirmation.
  Future<bool> deleteRoutine(String id) async {
    state = state.copyWith(isActionLoading: true, clearErrorMessage: true);
    try {
      await _repository.deleteRoutine(id);
      state = state.copyWith(
        routines: state.routines.where((r) => r.id != id).toList(),
        isActionLoading: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Failed to delete routine.',
      );
      return false;
    }
  }

  /// Adds an activity item to a routine, respecting the limit of 50 items.
  Future<bool> addItem({
    required String routineId,
    required String activityId,
    DateTime? scheduledDate,
  }) async {
    final routine = state.routines.firstWhere(
      (r) => r.id == routineId,
      orElse: () => Routine(id: '', title: '', createdAt: DateTime.now()),
    );
    if (routine.items.length >= 50) {
      state = state.copyWith(
        errorMessage:
            'You have reached the maximum limit of 50 activities for this routine.',
      );
      return false;
    }

    state = state.copyWith(isActionLoading: true, clearErrorMessage: true);
    try {
      final newItem = await _repository.addItem(
        routineId: routineId,
        activityId: activityId,
        scheduledDate: scheduledDate,
      );

      final nextRoutines = state.routines.map((r) {
        if (r.id == routineId) {
          return r.copyWith(items: [...r.items, newItem]);
        }
        return r;
      }).toList();

      state = state.copyWith(
        routines: nextRoutines,
        isActionLoading: false,
      );
      return true;
    } on RoutineItemLimitExceededException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return false;
    } on ApiException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Failed to add activity to routine.',
      );
      return false;
    }
  }

  /// Toggles item completion status.
  Future<bool> toggleItemDone({
    required String routineId,
    required String itemId,
    required bool isDone,
  }) async {
    state = state.copyWith(isActionLoading: true, clearErrorMessage: true);
    try {
      final updatedItem = await _repository.updateItem(
        routineId: routineId,
        itemId: itemId,
        isCompleted: isDone,
      );

      final nextRoutines = state.routines.map((r) {
        if (r.id == routineId) {
          final nextItems = r.items.map((i) {
            return i.id == itemId ? updatedItem : i;
          }).toList();
          return r.copyWith(items: nextItems);
        }
        return r;
      }).toList();

      state = state.copyWith(
        routines: nextRoutines,
        isActionLoading: false,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Failed to update item status.',
      );
      return false;
    }
  }

  /// Deletes an item from a routine.
  Future<bool> deleteItem({
    required String routineId,
    required String itemId,
  }) async {
    state = state.copyWith(isActionLoading: true, clearErrorMessage: true);
    try {
      await _repository.deleteItem(routineId: routineId, itemId: itemId);

      final nextRoutines = state.routines.map((r) {
        if (r.id == routineId) {
          final nextItems = r.items.where((i) => i.id != itemId).toList();
          return r.copyWith(items: nextItems);
        }
        return r;
      }).toList();

      state = state.copyWith(
        routines: nextRoutines,
        isActionLoading: false,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Failed to remove item.',
      );
      return false;
    }
  }

  /// Reorders items in a routine.
  Future<bool> reorderItems({
    required String routineId,
    required int oldIndex,
    required int newIndex,
  }) async {
    final routine = state.routines.firstWhere((r) => r.id == routineId);
    if (oldIndex < 0 ||
        oldIndex >= routine.items.length ||
        newIndex < 0 ||
        newIndex >= routine.items.length) {
      return false;
    }

    final updatedItems = List<RoutineItem>.from(routine.items);
    final movedItem = updatedItems.removeAt(oldIndex);
    updatedItems.insert(newIndex, movedItem);

    final nextRoutines = state.routines.map((r) {
      return r.id == routineId ? r.copyWith(items: updatedItems) : r;
    }).toList();

    state = state.copyWith(routines: nextRoutines);

    try {
      final itemIds = updatedItems.map((i) => i.id).toList();
      await _repository.reorderItems(
        routineId: routineId,
        itemIdsInOrder: itemIds,
      );
      return true;
    } catch (_) {
      await loadRoutines();
      return false;
    }
  }

  void clearAllUserData() {
    state = const RoutinesState();
  }
}

/// Provider for RoutinesNotifier.
final routinesNotifierProvider =
    NotifierProvider<RoutinesNotifier, RoutinesState>(RoutinesNotifier.new);
