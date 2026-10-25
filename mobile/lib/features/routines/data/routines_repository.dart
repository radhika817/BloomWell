import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../domain/entities/routine.dart';
import '../domain/entities/routine_item.dart';

/// Exception thrown when the user reaches the maximum allowed routines limit (20).
class RoutineLimitExceededException extends ApiException {
  const RoutineLimitExceededException({
    super.message = 'You have reached the maximum limit of 20 routines.',
    super.code = 'routine_limit_exceeded',
    super.requestId,
  });
}

/// Exception thrown when the user reaches the maximum allowed items per routine limit (50).
class RoutineItemLimitExceededException extends ApiException {
  const RoutineItemLimitExceededException({
    super.message =
        'You have reached the maximum limit of 50 activities for this routine.',
    super.code = 'routine_item_limit_exceeded',
    super.requestId,
  });
}

/// Contract for routine operations.
abstract class IRoutinesRepository {
  Future<List<Routine>> getRoutines();

  Future<Routine> getRoutine(String id);

  Future<Routine> createRoutine({
    required String title,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Routine> updateRoutine({
    required String id,
    String? title,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
  });

  Future<void> deleteRoutine(String id);

  Future<RoutineItem> addItem({
    required String routineId,
    required String activityId,
    DateTime? scheduledDate,
  });

  Future<RoutineItem> updateItem({
    required String routineId,
    required String itemId,
    DateTime? scheduledDate,
    bool clearScheduledDate = false,
    bool? isCompleted,
    int? position,
  });

  Future<void> deleteItem({
    required String routineId,
    required String itemId,
  });

  Future<List<RoutineItem>> reorderItems({
    required String routineId,
    required List<String> itemIdsInOrder,
  });
}

/// Remote implementation of IRoutinesRepository backed by the centralized ApiClient.
class RoutinesRepository implements IRoutinesRepository {
  const RoutinesRepository({required this.apiClient});

  final ApiClient apiClient;

  String? _formatDate(DateTime? dt) {
    if (dt == null) return null;
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  ApiException _mapRoutineError(DioException e) {
    final mapped = apiClient.mapDioError(e);
    final responseData = e.response?.data;
    if (responseData is Map<String, dynamic>) {
      final code = responseData['code'] as String?;
      final message = responseData['message'] as String? ?? '';
      if (code == 'ROUTINE_LIMIT_EXCEEDED' ||
          message.toLowerCase().contains('maximum number of routines')) {
        return RoutineLimitExceededException(
          message: message.isNotEmpty
              ? message
              : 'You have reached the maximum limit of 20 routines.',
          requestId: mapped.requestId,
        );
      }
      if (code == 'ROUTINE_ITEM_LIMIT_EXCEEDED' ||
          message.toLowerCase().contains('maximum items')) {
        return RoutineItemLimitExceededException(
          message: message.isNotEmpty
              ? message
              : 'You have reached the maximum limit of 50 activities for this routine.',
          requestId: mapped.requestId,
        );
      }
    }
    return mapped;
  }

  @override
  Future<List<Routine>> getRoutines() async {
    try {
      final response = await apiClient.dio.get<dynamic>(
        '/v1/routines',
      );

      final data = response.data;
      List<dynamic> itemsRaw = [];
      if (data is Map<String, dynamic>) {
        itemsRaw = data['items'] as List<dynamic>? ?? [];
      } else if (data is List<dynamic>) {
        itemsRaw = data;
      }

      return itemsRaw
          .map((r) => Routine.fromJson(r as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapRoutineError(e);
    }
  }

  @override
  Future<Routine> getRoutine(String id) async {
    try {
      final response = await apiClient.dio.get<Map<String, dynamic>>(
        '/v1/routines/$id',
      );
      return Routine.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapRoutineError(e);
    }
  }

  @override
  Future<Routine> createRoutine({
    required String title,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await apiClient.dio.post<Map<String, dynamic>>(
        '/v1/routines',
        data: {
          'title': title.trim(),
          if (startDate != null) 'start_date': _formatDate(startDate),
          if (endDate != null) 'end_date': _formatDate(endDate),
        },
      );
      return Routine.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapRoutineError(e);
    }
  }

  @override
  Future<Routine> updateRoutine({
    required String id,
    String? title,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (title != null) 'title': title.trim(),
        if (clearStartDate)
          'start_date': null
        else if (startDate != null)
          'start_date': _formatDate(startDate),
        if (clearEndDate)
          'end_date': null
        else if (endDate != null)
          'end_date': _formatDate(endDate),
      };

      final response = await apiClient.dio.patch<Map<String, dynamic>>(
        '/v1/routines/$id',
        data: payload,
      );
      return Routine.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapRoutineError(e);
    }
  }

  @override
  Future<void> deleteRoutine(String id) async {
    try {
      await apiClient.dio.delete<void>('/v1/routines/$id');
    } on DioException catch (e) {
      throw _mapRoutineError(e);
    }
  }

  @override
  Future<RoutineItem> addItem({
    required String routineId,
    required String activityId,
    DateTime? scheduledDate,
  }) async {
    try {
      final response = await apiClient.dio.post<Map<String, dynamic>>(
        '/v1/routines/$routineId/items',
        data: {
          'activity_id': activityId,
          if (scheduledDate != null)
            'scheduled_date': _formatDate(scheduledDate),
        },
      );
      return RoutineItem.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapRoutineError(e);
    }
  }

  @override
  Future<RoutineItem> updateItem({
    required String routineId,
    required String itemId,
    DateTime? scheduledDate,
    bool clearScheduledDate = false,
    bool? isCompleted,
    int? position,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (clearScheduledDate)
          'scheduled_date': null
        else if (scheduledDate != null)
          'scheduled_date': _formatDate(scheduledDate),
        if (isCompleted != null) 'completed': isCompleted,
        if (position != null) 'position': position,
      };

      final response = await apiClient.dio.patch<Map<String, dynamic>>(
        '/v1/routines/$routineId/items/$itemId',
        data: payload,
      );
      return RoutineItem.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapRoutineError(e);
    }
  }

  @override
  Future<void> deleteItem({
    required String routineId,
    required String itemId,
  }) async {
    try {
      await apiClient.dio.delete<void>('/v1/routines/$routineId/items/$itemId');
    } on DioException catch (e) {
      throw _mapRoutineError(e);
    }
  }

  @override
  Future<List<RoutineItem>> reorderItems({
    required String routineId,
    required List<String> itemIdsInOrder,
  }) async {
    try {
      final response = await apiClient.dio.put<dynamic>(
        '/v1/routines/$routineId/items/reorder',
        data: {'item_ids': itemIdsInOrder},
      );

      final data = response.data;
      List<dynamic> itemsRaw = [];
      if (data is Map<String, dynamic>) {
        itemsRaw = data['items'] as List<dynamic>? ?? [];
      } else if (data is List<dynamic>) {
        itemsRaw = data;
      }

      return itemsRaw
          .map((i) => RoutineItem.fromJson(i as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapRoutineError(e);
    }
  }
}
