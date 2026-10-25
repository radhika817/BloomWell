import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../domain/entities/activity_category.dart';
import '../domain/entities/activity_completion_log.dart';
import '../domain/entities/activity_entry.dart';
import '../domain/entities/activity_suggestion.dart';

/// Contract for Self-Care Studio activity catalog, completion, favorites, and history.
abstract class ISelfCareRepository {
  Future<({List<ActivityEntry> items, String? nextCursor, bool hasMore})>
      getActivities({
    ActivityCategory? category,
    int? maxDuration,
    String? cursor,
    int limit = 20,
  });

  Future<ActivityEntry> getActivityDetail(String id);

  Future<List<ActivitySuggestion>> getSuggestions({
    required String need,
    int? maxDuration,
  });

  Future<({List<ActivityEntry> items, String? nextCursor, bool hasMore})>
      getFavorites({
    String? cursor,
    int limit = 50,
  });

  Future<bool> setFavorite({
    required String activityId,
    required bool isFavorite,
  });

  Future<ActivityCompletionLog> completeActivity({
    required String clientId,
    required String activityId,
    int? helpfulnessRating,
  });

  Future<
      ({
        List<ActivityCompletionLog> items,
        String? nextCursor,
        bool hasMore
      })> getActivityHistory({
    String? cursor,
    int limit = 20,
  });
}

/// Remote implementation of ISelfCareRepository backed by the centralized Dio ApiClient.
class SelfCareRepository implements ISelfCareRepository {
  const SelfCareRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<({List<ActivityEntry> items, String? nextCursor, bool hasMore})>
      getActivities({
    ActivityCategory? category,
    int? maxDuration,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        if (category != null) 'category': category.apiValue,
        if (maxDuration != null) 'max_duration': maxDuration,
        if (cursor != null) 'cursor': cursor,
      };

      final response = await apiClient.dio.get<Map<String, dynamic>>(
        '/v1/activities',
        queryParameters: queryParams,
      );

      final data = response.data!;
      final itemsRaw = data['items'] as List<dynamic>? ?? [];
      final items = itemsRaw
          .map((a) => ActivityEntry.fromJson(a as Map<String, dynamic>))
          .toList();
      final nextCursor = data['next_cursor'] as String?;
      final hasMore = data['has_more'] as bool? ?? false;

      return (items: items, nextCursor: nextCursor, hasMore: hasMore);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<ActivityEntry> getActivityDetail(String id) async {
    try {
      final response = await apiClient.dio.get<Map<String, dynamic>>(
        '/v1/activities/$id',
      );
      return ActivityEntry.fromJson(response.data!);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<List<ActivitySuggestion>> getSuggestions({
    required String need,
    int? maxDuration,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'need': need,
        if (maxDuration != null) 'max_duration': maxDuration,
      };

      final response = await apiClient.dio.get<dynamic>(
        '/v1/activities/suggestions',
        queryParameters: queryParams,
      );

      final data = response.data;
      List<dynamic> itemsRaw = [];
      if (data is Map<String, dynamic>) {
        itemsRaw = data['items'] as List<dynamic>? ?? [];
      } else if (data is List<dynamic>) {
        itemsRaw = data;
      }

      return itemsRaw
          .map((s) => ActivitySuggestion.fromJson(s as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<({List<ActivityEntry> items, String? nextCursor, bool hasMore})>
      getFavorites({
    String? cursor,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      };

      final response = await apiClient.dio.get<Map<String, dynamic>>(
        '/v1/me/activities/favorites',
        queryParameters: queryParams,
      );

      final data = response.data!;
      final itemsRaw = data['items'] as List<dynamic>? ?? [];
      final items = itemsRaw
          .map((a) => ActivityEntry.fromJson(a as Map<String, dynamic>))
          .toList();
      final nextCursor = data['next_cursor'] as String?;
      final hasMore = data['has_more'] as bool? ?? false;

      return (items: items, nextCursor: nextCursor, hasMore: hasMore);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<bool> setFavorite({
    required String activityId,
    required bool isFavorite,
  }) async {
    try {
      if (isFavorite) {
        await apiClient.dio
            .post<dynamic>('/v1/activities/$activityId/favorite');
        return true;
      } else {
        await apiClient.dio
            .delete<dynamic>('/v1/activities/$activityId/favorite');
        return false;
      }
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<ActivityCompletionLog> completeActivity({
    required String clientId,
    required String activityId,
    int? helpfulnessRating,
  }) async {
    try {
      final response = await apiClient.dio.post<Map<String, dynamic>>(
        '/v1/activities/$activityId/complete',
        data: {
          'client_id': clientId,
          if (helpfulnessRating != null)
            'helpfulness_rating': helpfulnessRating,
        },
      );
      return ActivityCompletionLog.fromJson(response.data!);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<
      ({
        List<ActivityCompletionLog> items,
        String? nextCursor,
        bool hasMore
      })> getActivityHistory({
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      };

      final response = await apiClient.dio.get<Map<String, dynamic>>(
        '/v1/me/activities/history',
        queryParameters: queryParams,
      );

      final data = response.data!;
      final itemsRaw = data['items'] as List<dynamic>? ?? [];
      final items = itemsRaw
          .map((l) => ActivityCompletionLog.fromJson(l as Map<String, dynamic>))
          .toList();
      final nextCursor = data['next_cursor'] as String?;
      final hasMore = data['has_more'] as bool? ?? false;

      return (items: items, nextCursor: nextCursor, hasMore: hasMore);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }
}
