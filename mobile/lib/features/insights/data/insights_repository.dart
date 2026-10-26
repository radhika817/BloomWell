import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../domain/entities/exam_context_insights.dart';
import '../domain/entities/weekly_insights.dart';

/// Contract for personal insights API operations.
abstract class IInsightsRepository {
  Future<WeeklyInsights> getWeeklyInsights({String? weekStart});

  Future<ExamContextInsights> getExamContextInsights();
}

/// Remote implementation of IInsightsRepository backed by ApiClient.
class InsightsRepository implements IInsightsRepository {
  const InsightsRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<WeeklyInsights> getWeeklyInsights({String? weekStart}) async {
    try {
      final response = await apiClient.dio.get<Map<String, dynamic>>(
        '/v1/insights/weekly',
        queryParameters: {
          if (weekStart != null) 'week_start': weekStart,
        },
      );
      return WeeklyInsights.fromJson(response.data!);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<ExamContextInsights> getExamContextInsights() async {
    try {
      final response = await apiClient.dio.get<Map<String, dynamic>>(
        '/v1/insights/exam-context',
      );
      return ExamContextInsights.fromJson(response.data!);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }
}
