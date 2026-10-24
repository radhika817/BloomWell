import 'package:bloomwell/core/api/api_client.dart';
import 'package:bloomwell/core/api/api_exceptions.dart';
import 'package:bloomwell/features/cycle_care/data/cycle_care_repository.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_estimate.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_symptom_entry.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CycleCareRepository Tests', () {
    late Dio dio;
    late ApiClient apiClient;
    late CycleCareRepository repository;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000'));
      apiClient = ApiClient(dio: dio);
      repository = CycleCareRepository(apiClient: apiClient);
    });

    test('getCycleTrackingStatus returns parsed status', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, equals('/v1/me/cycle-tracking'));
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'cycle_tracking_enabled': true,
                  'consent_recorded_at': '2026-10-24T10:00:00Z',
                },
              ),
            );
          },
        ),
      );

      final status = await repository.getCycleTrackingStatus();
      expect(status.cycleTrackingEnabled, isTrue);
      expect(status.consentRecordedAt, isNotNull);
    });

    test('updateCycleTracking sends correct enabled and delete_data flags',
        () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, equals('/v1/me/cycle-tracking'));
            final data = options.data as Map<String, dynamic>;
            expect(data['cycle_tracking_enabled'], isFalse);
            expect(data['delete_data'], isTrue);

            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'cycle_tracking_enabled': false,
                  'consent_recorded_at': null,
                },
              ),
            );
          },
        ),
      );

      final result = await repository.updateCycleTracking(
        enabled: false,
        deleteData: true,
      );
      expect(result.cycleTrackingEnabled, isFalse);
      expect(result.consentRecordedAt, isNull);
    });

    test('getCycles passes from_date, to_date, cursor, and limit query params',
        () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, equals('/v1/cycles'));
            expect(options.queryParameters['from_date'], equals('2026-10-01'));
            expect(options.queryParameters['to_date'], equals('2026-10-31'));
            expect(options.queryParameters['limit'], equals(20));

            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'items': [
                    {
                      'id': 'cycle-1',
                      'client_id': 'c-1',
                      'period_start': '2026-10-05',
                      'period_end': '2026-10-09',
                      'cycle_length_days': 28,
                    }
                  ],
                  'next_cursor': null,
                  'has_more': false,
                },
              ),
            );
          },
        ),
      );

      final result = await repository.getCycles(
        fromDate: '2026-10-01',
        toDate: '2026-10-31',
      );
      expect(result.items.length, equals(1));
      expect(result.items.first.periodStart, equals('2026-10-05'));
      expect(result.hasMore, isFalse);
    });

    test('createPeriod sends client_id, start and end dates', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, equals('/v1/cycles'));
            final data = options.data as Map<String, dynamic>;
            expect(data['client_id'], equals('session-uuid-1'));
            expect(data['period_start'], equals('2026-10-10'));
            expect(data['period_end'], equals('2026-10-14'));

            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'id': 'cycle-new',
                  'client_id': 'session-uuid-1',
                  'period_start': '2026-10-10',
                  'period_end': '2026-10-14',
                },
              ),
            );
          },
        ),
      );

      final entry = await repository.createPeriod(
        clientId: 'session-uuid-1',
        periodStart: '2026-10-10',
        periodEnd: '2026-10-14',
      );
      expect(entry.id, equals('cycle-new'));
      expect(entry.clientId, equals('session-uuid-1'));
    });

    test('updatePeriod and deletePeriod call correct REST methods', () async {
      bool deleteCalled = false;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.method == 'PATCH') {
              expect(options.path, equals('/v1/cycles/c-123'));
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'id': 'c-123',
                    'client_id': 'cid',
                    'period_start': '2026-10-01',
                    'period_end': '2026-10-06',
                  },
                ),
              );
            } else if (options.method == 'DELETE') {
              expect(options.path, equals('/v1/cycles/c-123'));
              deleteCalled = true;
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 204,
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final updated = await repository.updatePeriod(
        id: 'c-123',
        periodEnd: '2026-10-06',
      );
      expect(updated.periodEnd, equals('2026-10-06'));

      await repository.deletePeriod('c-123');
      expect(deleteCalled, isTrue);
    });

    test('createSymptom sends symptom details with custom label', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, equals('/v1/symptoms'));
            final data = options.data as Map<String, dynamic>;
            expect(data['client_id'], equals('sym-client-id'));
            expect(data['symptom_type'], equals('other'));
            expect(data['custom_label'], equals('Lower pelvic ache'));
            expect(data['severity'], equals(4));

            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'id': 'sym-id-1',
                  'client_id': 'sym-client-id',
                  'date': '2026-10-24',
                  'symptom_type': 'other',
                  'custom_label': 'Lower pelvic ache',
                  'severity': 4,
                  'notes': 'Recorded symptom',
                },
              ),
            );
          },
        ),
      );

      final result = await repository.createSymptom(
        clientId: 'sym-client-id',
        date: '2026-10-24',
        symptomType: CycleSymptomType.other,
        customLabel: 'Lower pelvic ache',
        severity: 4,
        notes: 'Recorded symptom',
      );
      expect(result.symptomType, equals(CycleSymptomType.other));
      expect(result.customLabel, equals('Lower pelvic ache'));
    });

    test('getCycleHistoryInsight parses recent cycles and estimate object',
        () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, equals('/v1/insights/cycle-history'));
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'recent_cycles': [
                    {
                      'id': 'p-1',
                      'client_id': 'c-1',
                      'period_start': '2026-09-01',
                      'period_end': '2026-09-05',
                      'cycle_length_days': 28,
                    }
                  ],
                  'estimate': {
                    'status': 'estimate',
                    'typical_cycle_length_days': 28,
                    'cycles_counted': 3,
                    'estimated_range_start': '2026-10-28',
                    'estimated_range_end': '2026-11-01',
                  },
                },
              ),
            );
          },
        ),
      );

      final insight = await repository.getCycleHistoryInsight();
      expect(insight.recentCycles.length, equals(1));
      expect(insight.estimate.status, equals(CycleEstimateStatus.estimate));
      expect(insight.estimate.typicalCycleLengthDays, equals(28));
      expect(insight.estimate.estimatedRangeStart, equals('2026-10-28'));
    });

    test('Throws CycleTrackingDisabledException on HTTP 403', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 403,
                  data: {
                    'code': 'cycle_tracking_disabled',
                    'message': 'Cycle tracking is disabled for this account.',
                  },
                ),
              ),
            );
          },
        ),
      );

      expect(
        () => repository.getCycles(),
        throwsA(isA<CycleTrackingDisabledException>()),
      );
    });
  });
}
