import 'dart:convert';
import 'package:bloomwell/core/api/api_client.dart';
import 'package:bloomwell/core/api/api_exceptions.dart';
import 'package:bloomwell/features/insights/data/insights_repository.dart';
import 'package:bloomwell/features/insights/domain/entities/insight_status.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockAdapter implements HttpClientAdapter {
  _MockAdapter(this.handler);
  final Response<dynamic> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final res = handler(options);
    final data = res.data;
    if (res.statusCode != null && res.statusCode! >= 400) {
      throw DioException(
        requestOptions: options,
        response: res,
        type: DioExceptionType.badResponse,
      );
    }
    final text = data is String ? data : jsonEncode(data);
    return ResponseBody.fromString(
      text,
      res.statusCode ?? 200,
      headers: {
        'content-type': ['application/json']
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('InsightsRepository Unit Tests', () {
    late Dio dio;
    late ApiClient apiClient;
    late InsightsRepository repository;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://test'));
      apiClient = ApiClient(dio: dio);
      repository = InsightsRepository(apiClient: apiClient);
    });

    test('getWeeklyInsights parses sufficient data correctly', () async {
      dio.httpClientAdapter = _MockAdapter((options) {
        expect(options.path, equals('/v1/insights/weekly'));
        expect(options.queryParameters['week_start'], equals('2026-10-19'));
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'status': 'sufficient_data',
            'week_start': '2026-10-19',
            'metrics': {
              'stress': {
                'week_average': 2.0,
                'baseline_average': 3.1,
                'diff': -1.1,
                'code': 'LOWER_THAN_USUAL'
              },
              'mood': {
                'week_average': 4.0,
                'baseline_average': 3.2,
                'diff': 0.8,
                'code': 'HIGHER_THAN_USUAL'
              }
            },
            'sample_sizes': {
              'week_distinct_days': 5,
              'baseline_distinct_days': 14
            }
          },
        );
      });

      final insights =
          await repository.getWeeklyInsights(weekStart: '2026-10-19');
      expect(insights.status, equals(InsightStatus.sufficientData));
      expect(insights.hasSufficientData, isTrue);
      expect(insights.metrics?['stress']?.code, equals('LOWER_THAN_USUAL'));
      expect(insights.sampleSizes?.weekDistinctDays, equals(5));
      expect(insights.sampleSizes?.baselineDistinctDays, equals(14));
    });

    test('getWeeklyInsights parses not_enough_data correctly', () async {
      dio.httpClientAdapter = _MockAdapter((options) {
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'status': 'not_enough_data',
            'week_start': '2026-10-19',
            'days_needed': {'week': 2, 'baseline': 1}
          },
        );
      });

      final insights = await repository.getWeeklyInsights();
      expect(insights.status, equals(InsightStatus.notEnoughData));
      expect(insights.hasSufficientData, isFalse);
      expect(insights.daysNeeded?.week, equals(2));
      expect(insights.daysNeeded?.baseline, equals(1));
    });

    test('getExamContextInsights parses sufficient data correctly', () async {
      dio.httpClientAdapter = _MockAdapter((options) {
        expect(options.path, equals('/v1/insights/exam-context'));
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'status': 'sufficient_data',
            'qualifying_events_count': 2,
            'stress': {
              'pre_event_average': 4.5,
              'baseline_average': 2.8,
              'diff': 1.7,
              'code': 'STRESS_HIGHER_BEFORE_EVENTS'
            },
            'energy': {
              'pre_event_average': 2.2,
              'baseline_average': 3.8,
              'diff': -1.6,
              'code': 'ENERGY_LOWER_BEFORE_EVENTS'
            },
            'sample_sizes': {
              'pre_event_distinct_days': 6,
              'baseline_distinct_days': 12,
              'qualifying_events': 2
            }
          },
        );
      });

      final exam = await repository.getExamContextInsights();
      expect(exam.status, equals(InsightStatus.sufficientData));
      expect(exam.hasSufficientData, isTrue);
      expect(exam.stress?.code, equals('STRESS_HIGHER_BEFORE_EVENTS'));
      expect(exam.energy?.code, equals('ENERGY_LOWER_BEFORE_EVENTS'));
      expect(exam.sampleSizes?.qualifyingEvents, equals(2));
    });

    test('getExamContextInsights throws mapped ApiException on server error',
        () async {
      dio.httpClientAdapter = _MockAdapter((options) {
        return Response(
          requestOptions: options,
          statusCode: 500,
          data: {'code': 'INTERNAL_ERROR', 'message': 'Internal error'},
        );
      });

      expect(
        () => repository.getExamContextInsights(),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
