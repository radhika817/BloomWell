import 'dart:convert';
import 'package:bloomwell/core/api/api_client.dart';
import 'package:bloomwell/core/api/api_exceptions.dart';
import 'package:bloomwell/features/study_planner/data/study_planner_repository.dart';
import 'package:bloomwell/features/study_planner/domain/entities/plan_item_status.dart';
import 'package:bloomwell/features/study_planner/domain/entities/study_plan_mode.dart';
import 'package:bloomwell/features/study_planner/domain/entities/suggested_load.dart';
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
  group('StudyPlannerRepository Unit Tests', () {
    late Dio dio;
    late ApiClient apiClient;
    late StudyPlannerRepository repository;

    final samplePlanJson = {
      'id': 'plan-101',
      'week_start': '2026-11-02',
      'days': 7,
      'mode': 'personalized',
      'uses_cycle_data': false,
      'personalization': {
        'status': 'personalized',
        'checkin_days_used': 15,
        'checkin_days_needed': 14,
      },
      'items': [
        {
          'id': 'item-1',
          'study_plan_id': 'plan-101',
          'plan_date': '2026-11-02',
          'suggested_load': 'focus',
          'reason_codes': ['WEEKDAY_ENERGY_HIGHER'],
          'academic_event_id': null,
          'activity_id': 'act-1',
          'status': 'suggested',
          'updated_at': '2026-10-26T10:00:00Z',
        }
      ],
      'created_at': '2026-10-26T10:00:00Z',
    };

    final sampleItemJson = {
      'id': 'item-1',
      'study_plan_id': 'plan-101',
      'plan_date': '2026-11-02',
      'suggested_load': 'light',
      'reason_codes': ['WEEKDAY_ENERGY_HIGHER'],
      'academic_event_id': null,
      'activity_id': 'act-1',
      'status': 'edited',
      'updated_at': '2026-10-26T11:00:00Z',
    };

    final sampleConsentJson = {
      'enabled': true,
      'consent_recorded_at': '2026-10-26T10:00:00Z',
      'deleted_cycle_plans_count': 0,
    };

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://test'));
      apiClient = ApiClient(dio: dio);
      repository = StudyPlannerRepository(apiClient: apiClient);
    });

    test('generatePlan returns parsed StudyPlan on 201', () async {
      dio.httpClientAdapter = _MockAdapter((options) {
        expect(options.path, equals('/v1/study-plans/generate'));
        expect(options.data,
            equals({'week_start': '2026-11-02', 'replace': false}));
        return Response(
          requestOptions: options,
          statusCode: 201,
          data: samplePlanJson,
        );
      });

      final plan = await repository.generatePlan(weekStart: '2026-11-02');
      expect(plan.id, equals('plan-101'));
      expect(plan.mode, equals(StudyPlanMode.personalized));
      expect(plan.items.length, equals(1));
      expect(plan.items.first.suggestedLoad, equals(SuggestedLoad.focus));
    });

    test('generatePlan maps 409 plan_exists to PlanExistsException', () async {
      dio.httpClientAdapter = _MockAdapter((options) {
        return Response(
          requestOptions: options,
          statusCode: 409,
          data: {
            'error': {
              'code': 'plan_exists',
              'message': 'A study plan already exists for this week.',
            },
            'request_id': 'req-999',
          },
        );
      });

      expect(
        () => repository.generatePlan(weekStart: '2026-11-02'),
        throwsA(isA<PlanExistsException>()),
      );
    });

    test('getCurrentPlan returns StudyPlan on 200 and null on 404', () async {
      dio.httpClientAdapter = _MockAdapter((options) {
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: samplePlanJson,
        );
      });

      final plan = await repository.getCurrentPlan();
      expect(plan, isNotNull);
      expect(plan!.id, equals('plan-101'));

      // Now 404
      dio.httpClientAdapter = _MockAdapter((options) {
        return Response(
          requestOptions: options,
          statusCode: 404,
          data: {
            'error': {
              'code': 'not_found',
              'message': 'No study plan found for current week.',
            }
          },
        );
      });

      final notFoundPlan = await repository.getCurrentPlan();
      expect(notFoundPlan, isNull);
    });

    test('getPlanByWeek returns StudyPlan on 200 and null on 404', () async {
      dio.httpClientAdapter = _MockAdapter((options) {
        expect(options.queryParameters['week_start'], equals('2026-11-02'));
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: samplePlanJson,
        );
      });

      final plan = await repository.getPlanByWeek('2026-11-02');
      expect(plan, isNotNull);
      expect(plan!.id, equals('plan-101'));

      // 404
      dio.httpClientAdapter = _MockAdapter((options) {
        return Response(
          requestOptions: options,
          statusCode: 404,
          data: {
            'error': {'code': 'not_found', 'message': 'Not found'}
          },
        );
      });

      final notFound = await repository.getPlanByWeek('2026-11-09');
      expect(notFound, isNull);
    });

    test('deletePlan issues DELETE request', () async {
      var called = false;
      dio.httpClientAdapter = _MockAdapter((options) {
        expect(options.path, equals('/v1/study-plans/plan-101'));
        expect(options.method, equals('DELETE'));
        called = true;
        return Response(
          requestOptions: options,
          statusCode: 204,
          data: null,
        );
      });

      await repository.deletePlan('plan-101');
      expect(called, isTrue);
    });

    test('patchItem sends status and suggested_load when edited', () async {
      dio.httpClientAdapter = _MockAdapter((options) {
        expect(options.path, equals('/v1/study-plans/items/item-1'));
        expect(options.method, equals('PATCH'));
        expect(
            options.data,
            equals({
              'status': 'edited',
              'suggested_load': 'light',
            }));
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: sampleItemJson,
        );
      });

      final item = await repository.patchItem(
        itemId: 'item-1',
        status: PlanItemStatus.edited,
        suggestedLoad: SuggestedLoad.light,
      );
      expect(item.id, equals('item-1'));
      expect(item.status, equals(PlanItemStatus.edited));
      expect(item.suggestedLoad, equals(SuggestedLoad.light));
    });

    test('getPlannerCycleConsent returns parsed consent', () async {
      dio.httpClientAdapter = _MockAdapter((options) {
        expect(options.path, equals('/v1/me/planner-cycle-consent'));
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: sampleConsentJson,
        );
      });

      final consent = await repository.getPlannerCycleConsent();
      expect(consent.enabled, isTrue);
      expect(consent.deletedCyclePlansCount, equals(0));
    });

    test('updatePlannerCycleConsent maps 409 cycle_tracking_required',
        () async {
      dio.httpClientAdapter = _MockAdapter((options) {
        return Response(
          requestOptions: options,
          statusCode: 409,
          data: {
            'error': {
              'code': 'cycle_tracking_required',
              'message': 'Cycle tracking must be enabled first.',
            }
          },
        );
      });

      expect(
        () => repository.updatePlannerCycleConsent(enabled: true),
        throwsA(isA<CycleTrackingRequiredException>()),
      );
    });
  });
}
