import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../domain/entities/cycle_history_insight.dart';
import '../domain/entities/cycle_period_entry.dart';
import '../domain/entities/cycle_symptom_entry.dart';
import '../domain/entities/cycle_tracking_status.dart';

/// Contract for cycle tracking operations.
abstract class ICycleCareRepository {
  Future<CycleTrackingStatus> getCycleTrackingStatus();

  Future<CycleTrackingStatus> updateCycleTracking({
    required bool enabled,
    bool deleteData = false,
  });

  Future<({List<CyclePeriodEntry> items, String? nextCursor, bool hasMore})>
      getCycles({
    String? fromDate,
    String? toDate,
    String? cursor,
    int limit = 20,
  });

  Future<CyclePeriodEntry> createPeriod({
    required String clientId,
    required String periodStart,
    String? periodEnd,
  });

  Future<CyclePeriodEntry> updatePeriod({
    required String id,
    String? periodStart,
    String? periodEnd,
  });

  Future<void> deletePeriod(String id);

  Future<({List<CycleSymptomEntry> items, String? nextCursor, bool hasMore})>
      getSymptoms({
    String? fromDate,
    String? toDate,
    String? cursor,
    int limit = 50,
  });

  Future<CycleSymptomEntry> createSymptom({
    required String clientId,
    required String date,
    required CycleSymptomType symptomType,
    String? customLabel,
    required int severity,
    String? notes,
  });

  Future<CycleSymptomEntry> updateSymptom({
    required String id,
    String? date,
    CycleSymptomType? symptomType,
    String? customLabel,
    int? severity,
    String? notes,
  });

  Future<void> deleteSymptom(String id);

  Future<CycleHistoryInsight> getCycleHistoryInsight();
}

/// Remote implementation of ICycleCareRepository backed by the centralized Dio ApiClient.
class CycleCareRepository implements ICycleCareRepository {
  const CycleCareRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<CycleTrackingStatus> getCycleTrackingStatus() async {
    try {
      final response = await apiClient.dio.get<Map<String, dynamic>>(
        '/v1/me/cycle-tracking',
      );
      return CycleTrackingStatus.fromJson(response.data!);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<CycleTrackingStatus> updateCycleTracking({
    required bool enabled,
    bool deleteData = false,
  }) async {
    try {
      final response = await apiClient.dio.put<Map<String, dynamic>>(
        '/v1/me/cycle-tracking',
        data: {
          'cycle_tracking_enabled': enabled,
          'delete_data': deleteData,
        },
      );
      return CycleTrackingStatus.fromJson(response.data!);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<({List<CyclePeriodEntry> items, String? nextCursor, bool hasMore})>
      getCycles({
    String? fromDate,
    String? toDate,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
        if (cursor != null) 'cursor': cursor,
      };

      final response = await apiClient.dio.get<Map<String, dynamic>>(
        '/v1/cycles',
        queryParameters: queryParams,
      );

      final data = response.data!;
      final itemsRaw = data['items'] as List<dynamic>? ?? [];
      final items = itemsRaw
          .map((c) => CyclePeriodEntry.fromJson(c as Map<String, dynamic>))
          .toList();
      final nextCursor = data['next_cursor'] as String?;
      final hasMore = data['has_more'] as bool? ?? false;

      return (items: items, nextCursor: nextCursor, hasMore: hasMore);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<CyclePeriodEntry> createPeriod({
    required String clientId,
    required String periodStart,
    String? periodEnd,
  }) async {
    try {
      final response = await apiClient.dio.post<Map<String, dynamic>>(
        '/v1/cycles',
        data: {
          'client_id': clientId,
          'period_start': periodStart,
          if (periodEnd != null && periodEnd.isNotEmpty)
            'period_end': periodEnd,
        },
      );
      return CyclePeriodEntry.fromJson(response.data!);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<CyclePeriodEntry> updatePeriod({
    required String id,
    String? periodStart,
    String? periodEnd,
  }) async {
    try {
      final response = await apiClient.dio.patch<Map<String, dynamic>>(
        '/v1/cycles/$id',
        data: {
          if (periodStart != null) 'period_start': periodStart,
          'period_end': periodEnd,
        },
      );
      return CyclePeriodEntry.fromJson(response.data!);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<void> deletePeriod(String id) async {
    try {
      await apiClient.dio.delete<void>('/v1/cycles/$id');
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<({List<CycleSymptomEntry> items, String? nextCursor, bool hasMore})>
      getSymptoms({
    String? fromDate,
    String? toDate,
    String? cursor,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
        if (cursor != null) 'cursor': cursor,
      };

      final response = await apiClient.dio.get<Map<String, dynamic>>(
        '/v1/symptoms',
        queryParameters: queryParams,
      );

      final data = response.data!;
      final itemsRaw = data['items'] as List<dynamic>? ?? [];
      final items = itemsRaw
          .map((s) => CycleSymptomEntry.fromJson(s as Map<String, dynamic>))
          .toList();
      final nextCursor = data['next_cursor'] as String?;
      final hasMore = data['has_more'] as bool? ?? false;

      return (items: items, nextCursor: nextCursor, hasMore: hasMore);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<CycleSymptomEntry> createSymptom({
    required String clientId,
    required String date,
    required CycleSymptomType symptomType,
    String? customLabel,
    required int severity,
    String? notes,
  }) async {
    try {
      final response = await apiClient.dio.post<Map<String, dynamic>>(
        '/v1/symptoms',
        data: {
          'client_id': clientId,
          'date': date,
          'symptom_type': symptomType.apiValue,
          if (customLabel != null && customLabel.trim().isNotEmpty)
            'custom_label': customLabel.trim(),
          'severity': severity,
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        },
      );
      return CycleSymptomEntry.fromJson(response.data!);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<CycleSymptomEntry> updateSymptom({
    required String id,
    String? date,
    CycleSymptomType? symptomType,
    String? customLabel,
    int? severity,
    String? notes,
  }) async {
    try {
      final response = await apiClient.dio.patch<Map<String, dynamic>>(
        '/v1/symptoms/$id',
        data: {
          if (date != null) 'date': date,
          if (symptomType != null) 'symptom_type': symptomType.apiValue,
          'custom_label': customLabel,
          if (severity != null) 'severity': severity,
          'notes': notes,
        },
      );
      return CycleSymptomEntry.fromJson(response.data!);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<void> deleteSymptom(String id) async {
    try {
      await apiClient.dio.delete<void>('/v1/symptoms/$id');
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<CycleHistoryInsight> getCycleHistoryInsight() async {
    try {
      final response = await apiClient.dio.get<Map<String, dynamic>>(
        '/v1/insights/cycle-history',
      );
      return CycleHistoryInsight.fromJson(response.data!);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }
}
