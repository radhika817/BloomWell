import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../domain/entities/plan_item_status.dart';
import '../domain/entities/planner_cycle_consent.dart';
import '../domain/entities/study_plan.dart';
import '../domain/entities/study_plan_item.dart';
import '../domain/entities/suggested_load.dart';

/// Contract for Study Planner API interactions.
abstract class IStudyPlannerRepository {
  Future<StudyPlan> generatePlan({
    required String weekStart,
    bool replace = false,
  });

  Future<StudyPlan?> getCurrentPlan();

  Future<StudyPlan?> getPlanByWeek(String weekStart);

  Future<StudyPlan?> getPlanById(String id);

  Future<void> deletePlan(String id);

  Future<StudyPlanItem> patchItem({
    required String itemId,
    required PlanItemStatus status,
    SuggestedLoad? suggestedLoad,
  });

  Future<PlannerCycleConsent> getPlannerCycleConsent();

  Future<PlannerCycleConsent> updatePlannerCycleConsent({
    required bool enabled,
  });
}

/// Remote implementation of IStudyPlannerRepository backed by the centralized ApiClient.
class StudyPlannerRepository implements IStudyPlannerRepository {
  const StudyPlannerRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<StudyPlan> generatePlan({
    required String weekStart,
    bool replace = false,
  }) async {
    try {
      final response = await apiClient.dio.post<Map<String, dynamic>>(
        '/v1/study-plans/generate',
        data: {
          'week_start': weekStart,
          'replace': replace,
        },
      );
      return StudyPlan.fromJson(response.data!);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<StudyPlan?> getCurrentPlan() async {
    try {
      final response = await apiClient.dio.get<Map<String, dynamic>>(
        '/v1/study-plans/current',
      );
      return StudyPlan.fromJson(response.data!);
    } on DioException catch (e) {
      final mapped = apiClient.mapDioError(e);
      if (mapped is NotFoundException) {
        return null;
      }
      throw mapped;
    }
  }

  @override
  Future<StudyPlan?> getPlanByWeek(String weekStart) async {
    try {
      final response = await apiClient.dio.get<Map<String, dynamic>>(
        '/v1/study-plans',
        queryParameters: {'week_start': weekStart},
      );
      return StudyPlan.fromJson(response.data!);
    } on DioException catch (e) {
      final mapped = apiClient.mapDioError(e);
      if (mapped is NotFoundException) {
        return null;
      }
      throw mapped;
    }
  }

  @override
  Future<StudyPlan?> getPlanById(String id) async {
    try {
      final response = await apiClient.dio.get<Map<String, dynamic>>(
        '/v1/study-plans/$id',
      );
      return StudyPlan.fromJson(response.data!);
    } on DioException catch (e) {
      final mapped = apiClient.mapDioError(e);
      if (mapped is NotFoundException) {
        return null;
      }
      throw mapped;
    }
  }

  @override
  Future<void> deletePlan(String id) async {
    try {
      await apiClient.dio.delete<void>('/v1/study-plans/$id');
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<StudyPlanItem> patchItem({
    required String itemId,
    required PlanItemStatus status,
    SuggestedLoad? suggestedLoad,
  }) async {
    try {
      final payload = <String, dynamic>{
        'status': status.apiValue,
        if (status == PlanItemStatus.edited && suggestedLoad != null)
          'suggested_load': suggestedLoad.apiValue,
      };

      final response = await apiClient.dio.patch<Map<String, dynamic>>(
        '/v1/study-plans/items/$itemId',
        data: payload,
      );
      return StudyPlanItem.fromJson(response.data!);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<PlannerCycleConsent> getPlannerCycleConsent() async {
    try {
      final response = await apiClient.dio.get<Map<String, dynamic>>(
        '/v1/me/planner-cycle-consent',
      );
      return PlannerCycleConsent.fromJson(response.data!);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<PlannerCycleConsent> updatePlannerCycleConsent({
    required bool enabled,
  }) async {
    try {
      final response = await apiClient.dio.put<Map<String, dynamic>>(
        '/v1/me/planner-cycle-consent',
        data: {'enabled': enabled},
      );
      return PlannerCycleConsent.fromJson(response.data!);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }
}
