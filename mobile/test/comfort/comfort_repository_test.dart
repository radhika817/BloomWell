import 'package:bloomwell/core/api/api_client.dart';
import 'package:bloomwell/features/comfort/data/comfort_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ComfortRepository Unit Tests', () {
    late Dio dio;
    late ApiClient apiClient;
    late ComfortRepository repository;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000'));
      apiClient = ApiClient(dio: dio);
      repository = ComfortRepository(apiClient: apiClient);
    });

    test('getComfortPlan retrieves saved items', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, equals('/v1/me/comfort-plan'));
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'items': [
                    {
                      'id': 'cp-1',
                      'activity_id': 'act-warm',
                      'position': 0,
                      'created_at': '2026-10-24T10:00:00Z',
                      'activity': {
                        'id': 'act-warm',
                        'title': 'Warm Compress Rest',
                        'category': 'comfort',
                        'duration_minutes': 10,
                        'summary': 'Rest with gentle heat',
                        'steps': ['Warm heating pad', 'Rest for 10 minutes'],
                        'source': 'Self-Care Studio',
                      },
                    }
                  ],
                },
              ),
            );
          },
        ),
      );

      final plan = await repository.getComfortPlan();
      expect(plan.length, 1);
      expect(plan.first.activityId, 'act-warm');
      expect(plan.first.activity?.title, 'Warm Compress Rest');
      expect(plan.first.activity?.isComfortCategory, isTrue);
    });

    test('addToComfortPlan posts activity_id and returns item', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, equals('/v1/me/comfort-plan/items'));
            final data = options.data as Map<String, dynamic>;
            expect(data['activity_id'], equals('act-new'));

            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'id': 'cp-2',
                  'activity_id': 'act-new',
                  'position': 1,
                  'created_at': '2026-10-24T11:00:00Z',
                },
              ),
            );
          },
        ),
      );

      final item = await repository.addToComfortPlan(activityId: 'act-new');
      expect(item.id, 'cp-2');
      expect(item.activityId, 'act-new');
    });

    test('removeFromComfortPlan sends DELETE with item id', () async {
      int deleteCalls = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, equals('DELETE'));
            expect(options.path, equals('/v1/me/comfort-plan/items/cp-del'));
            deleteCalls++;
            return handler.resolve(
              Response(requestOptions: options, statusCode: 204),
            );
          },
        ),
      );

      await repository.removeFromComfortPlan('cp-del');
      expect(deleteCalls, 1);
    });

    test('reorderComfortPlan sends ordered IDs and returns updated list',
        () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, equals('PUT'));
            expect(options.path, equals('/v1/me/comfort-plan/reorder'));
            final data = options.data as Map<String, dynamic>;
            expect(data['item_ids'], equals(['cp-2', 'cp-1']));

            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: [
                  {
                    'id': 'cp-2',
                    'activity_id': 'act-2',
                    'position': 0,
                    'created_at': '2026-10-24T11:00:00Z',
                  },
                  {
                    'id': 'cp-1',
                    'activity_id': 'act-1',
                    'position': 1,
                    'created_at': '2026-10-24T10:00:00Z',
                  },
                ],
              ),
            );
          },
        ),
      );

      final reordered = await repository.reorderComfortPlan(['cp-2', 'cp-1']);
      expect(reordered.length, 2);
      expect(reordered.first.id, 'cp-2');
      expect(reordered[1].id, 'cp-1');
    });
  });
}
