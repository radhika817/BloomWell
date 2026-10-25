import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../domain/entities/academic_event.dart';
import '../domain/entities/academic_event_type.dart';

/// Contract for academic events and deadlines operations.
abstract class IAcademicEventsRepository {
  Future<({List<AcademicEvent> items, String? nextCursor, bool hasMore})>
      getEvents({
    bool? upcomingOnly,
    String? cursor,
    int limit = 50,
  });

  Future<AcademicEvent> createEvent({
    required String clientId,
    required String title,
    required DateTime eventDate,
    required AcademicEventType eventType,
  });

  Future<AcademicEvent> updateEvent({
    required String id,
    String? title,
    DateTime? eventDate,
    AcademicEventType? eventType,
  });

  Future<void> deleteEvent(String id);
}

/// Remote implementation of IAcademicEventsRepository backed by the centralized ApiClient.
class AcademicEventsRepository implements IAcademicEventsRepository {
  const AcademicEventsRepository({required this.apiClient});

  final ApiClient apiClient;

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Future<({List<AcademicEvent> items, String? nextCursor, bool hasMore})>
      getEvents({
    bool? upcomingOnly,
    String? cursor,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        if (upcomingOnly != null) 'upcoming_only': upcomingOnly,
        if (cursor != null) 'cursor': cursor,
      };

      final response = await apiClient.dio.get<Map<String, dynamic>>(
        '/v1/academic-events',
        queryParameters: queryParams,
      );

      final data = response.data!;
      final itemsRaw = data['items'] as List<dynamic>? ?? [];
      final items = itemsRaw
          .map((e) => AcademicEvent.fromJson(e as Map<String, dynamic>))
          .toList();
      final nextCursor = data['next_cursor'] as String?;
      final hasMore = data['has_more'] as bool? ?? false;

      return (items: items, nextCursor: nextCursor, hasMore: hasMore);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<AcademicEvent> createEvent({
    required String clientId,
    required String title,
    required DateTime eventDate,
    required AcademicEventType eventType,
  }) async {
    try {
      final response = await apiClient.dio.post<Map<String, dynamic>>(
        '/v1/academic-events',
        data: {
          'client_id': clientId,
          'title': title.trim(),
          'event_date': _formatDate(eventDate),
          'event_type': eventType.apiValue,
        },
      );
      return AcademicEvent.fromJson(response.data!);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<AcademicEvent> updateEvent({
    required String id,
    String? title,
    DateTime? eventDate,
    AcademicEventType? eventType,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (title != null) 'title': title.trim(),
        if (eventDate != null) 'event_date': _formatDate(eventDate),
        if (eventType != null) 'event_type': eventType.apiValue,
      };

      final response = await apiClient.dio.patch<Map<String, dynamic>>(
        '/v1/academic-events/$id',
        data: payload,
      );
      return AcademicEvent.fromJson(response.data!);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<void> deleteEvent(String id) async {
    try {
      await apiClient.dio.delete<void>('/v1/academic-events/$id');
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }
}
