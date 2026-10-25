import 'package:bloomwell/core/api/api_client.dart';
import 'package:bloomwell/features/routines/data/routines_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoutinesRepository Unit Tests', () {
    late Dio dio;
    late ApiClient apiClient;
    late RoutinesRepository repository;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000'));
      apiClient = ApiClient(dio: dio);
      repository = RoutinesRepository(apiClient: apiClient);
    });

    test('getRoutines fetches list of routines with items', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, equals('/v1/routines'));
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: [
                  {
                    'id': 'r-1',
                    'title': 'Morning Grounding',
                    'start_date': '2026-10-01',
                    'end_date': null,
                    'created_at': '2026-10-01T08:00:00Z',
                    'items': [
                      {
                        'id': 'i-1',
                        'routine_id': 'r-1',
                        'activity_id': 'act-1',
                        'title': 'Deep Breathing',
                        'scheduled_date': '2026-10-24',
                        'completed_at': null,
                        'position': 0,
                      }
                    ],
                  }
                ],
              ),
            );
          },
        ),
      );

      final routines = await repository.getRoutines();
      expect(routines.length, 1);
      expect(routines.first.title, 'Morning Grounding');
      expect(routines.first.items.length, 1);
      expect(routines.first.items.first.isDone, isFalse);
    });

    test('createRoutine sends title, start_date and maps created routine',
        () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, equals('/v1/routines'));
            final data = options.data as Map<String, dynamic>;
            expect(data['title'], equals('Exam Week Reset'));
            expect(data['start_date'], equals('2026-11-01'));

            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'id': 'r-new',
                  'title': 'Exam Week Reset',
                  'start_date': '2026-11-01',
                  'end_date': null,
                  'items': <dynamic>[],
                  'created_at': '2026-10-24T12:00:00Z',
                },
              ),
            );
          },
        ),
      );

      final routine = await repository.createRoutine(
        title: 'Exam Week Reset',
        startDate: DateTime(2026, 11, 1),
      );

      expect(routine.id, 'r-new');
      expect(routine.title, 'Exam Week Reset');
    });

    test('addItem and updateItem send correct payloads and map responses',
        () async {
      int addCalls = 0;
      int updateCalls = 0;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.method == 'POST' &&
                options.path == '/v1/routines/r-1/items') {
              addCalls++;
              final data = options.data as Map<String, dynamic>;
              expect(data['activity_id'], equals('act-10'));
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: {
                    'id': 'i-10',
                    'routine_id': 'r-1',
                    'activity_id': 'act-10',
                    'title': 'Body Scan',
                    'position': 0,
                  },
                ),
              );
            } else if (options.method == 'PATCH' &&
                options.path == '/v1/routines/r-1/items/i-10') {
              updateCalls++;
              final data = options.data as Map<String, dynamic>;
              expect(data['completed'], isTrue);
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'id': 'i-10',
                    'routine_id': 'r-1',
                    'activity_id': 'act-10',
                    'title': 'Body Scan',
                    'completed_at': '2026-10-24T14:00:00Z',
                    'position': 0,
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final added = await repository.addItem(
        routineId: 'r-1',
        activityId: 'act-10',
      );
      expect(added.id, 'i-10');
      expect(addCalls, 1);

      final updated = await repository.updateItem(
        routineId: 'r-1',
        itemId: 'i-10',
        isCompleted: true,
      );
      expect(updated.isDone, isTrue);
      expect(updateCalls, 1);
    });

    test('reorderItems sends ordered item IDs', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, equals('/v1/routines/r-1/items/reorder'));
            final data = options.data as Map<String, dynamic>;
            expect(data['item_ids'], equals(['i-2', 'i-1']));

            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: [
                  {
                    'id': 'i-2',
                    'routine_id': 'r-1',
                    'activity_id': 'act-2',
                    'title': 'Item 2',
                    'position': 0,
                  },
                  {
                    'id': 'i-1',
                    'routine_id': 'r-1',
                    'activity_id': 'act-1',
                    'title': 'Item 1',
                    'position': 1,
                  },
                ],
              ),
            );
          },
        ),
      );

      final result = await repository.reorderItems(
        routineId: 'r-1',
        itemIdsInOrder: ['i-2', 'i-1'],
      );
      expect(result.length, 2);
      expect(result.first.id, 'i-2');
    });

    test(
        'maps 422 or 400 routine limit errors into RoutineLimitExceededException',
        () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 422,
                  data: {
                    'code': 'ROUTINE_LIMIT_EXCEEDED',
                    'message': 'Maximum number of routines (20) reached.',
                  },
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );

      expect(
        () => repository.createRoutine(title: 'Exceeding limit'),
        throwsA(isA<RoutineLimitExceededException>()),
      );
    });
  });
}
