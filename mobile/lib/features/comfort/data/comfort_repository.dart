import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../domain/entities/comfort_plan_item.dart';

/// Contract for managing the user's personal comfort plan.
abstract class IComfortRepository {
  Future<List<ComfortPlanItem>> getComfortPlan();

  Future<ComfortPlanItem> addToComfortPlan({required String activityId});

  Future<void> removeFromComfortPlan(String itemId);

  Future<List<ComfortPlanItem>> reorderComfortPlan(List<String> itemIdsInOrder);
}

/// Remote implementation of IComfortRepository backed by ApiClient.
class ComfortRepository implements IComfortRepository {
  const ComfortRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<ComfortPlanItem>> getComfortPlan() async {
    try {
      final response = await apiClient.dio.get<dynamic>(
        '/v1/me/comfort-plan',
      );

      final data = response.data;
      List<dynamic> itemsRaw = [];
      if (data is Map<String, dynamic>) {
        itemsRaw = data['items'] as List<dynamic>? ?? [];
      } else if (data is List<dynamic>) {
        itemsRaw = data;
      }

      return itemsRaw
          .map((i) => ComfortPlanItem.fromJson(i as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<ComfortPlanItem> addToComfortPlan({required String activityId}) async {
    try {
      final response = await apiClient.dio.post<Map<String, dynamic>>(
        '/v1/me/comfort-plan/items',
        data: {'activity_id': activityId},
      );
      return ComfortPlanItem.fromJson(response.data!);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<void> removeFromComfortPlan(String itemId) async {
    try {
      await apiClient.dio.delete<void>('/v1/me/comfort-plan/items/$itemId');
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<List<ComfortPlanItem>> reorderComfortPlan(
      List<String> itemIdsInOrder) async {
    try {
      final response = await apiClient.dio.put<dynamic>(
        '/v1/me/comfort-plan/reorder',
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
          .map((i) => ComfortPlanItem.fromJson(i as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }
}
