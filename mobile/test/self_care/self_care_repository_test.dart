import 'package:bloomwell/core/api/api_client.dart';
import 'package:bloomwell/core/utils/uuid_generator.dart';
import 'package:bloomwell/features/self_care/data/self_care_repository.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_category.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_suggestion.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelfCareRepository Unit Tests', () {
    late Dio dio;
    late ApiClient apiClient;
    late SelfCareRepository repository;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000'));
      apiClient = ApiClient(dio: dio);
      repository = SelfCareRepository(apiClient: apiClient);
    });

    test('generateUuidV4 generates 36-character RFC-4122 v4 UUID', () {
      final uuid = generateUuidV4();
      expect(uuid.length, 36);
      expect(
          RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
              .hasMatch(uuid),
          isTrue);
    });

    test(
        'getActivities passes category, max_duration, cursor and parses pagination',
        () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, equals('/v1/activities'));
            expect(options.queryParameters['category'], equals('breathing'));
            expect(options.queryParameters['max_duration'], equals(5));
            expect(options.queryParameters['cursor'], equals('cur_abc'));

            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'items': [
                    {
                      'id': 'act-1',
                      'title': 'Box Breathing',
                      'category': 'breathing',
                      'duration_minutes': 4,
                      'summary': 'Calming 4x4 breathing',
                      'steps': ['Inhale', 'Hold', 'Exhale', 'Hold'],
                      'source': 'BloomWell Guide',
                      'is_favorite': true,
                    }
                  ],
                  'next_cursor': 'cur_def',
                  'has_more': true,
                },
              ),
            );
          },
        ),
      );

      final result = await repository.getActivities(
        category: ActivityCategory.breathing,
        maxDuration: 5,
        cursor: 'cur_abc',
      );

      expect(result.items.length, 1);
      expect(result.items.first.title, 'Box Breathing');
      expect(result.items.first.isFavorite, isTrue);
      expect(result.nextCursor, 'cur_def');
      expect(result.hasMore, isTrue);
    });

    test('getActivityDetail fetches single activity by id', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, equals('/v1/activities/act-42'));
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'act-42',
                  'title': 'Gentle Grounding',
                  'category': 'grounding',
                  'duration_minutes': 5,
                  'summary': '5-4-3-2-1 technique',
                  'steps': ['Look around', 'Touch something'],
                  'source': 'Student Wellness Center',
                },
              ),
            );
          },
        ),
      );

      final detail = await repository.getActivityDetail('act-42');
      expect(detail.id, 'act-42');
      expect(detail.category, ActivityCategory.grounding);
    });

    test('getSuggestions passes need and max_duration correctly', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, equals('/v1/activities/suggestions'));
            expect(options.queryParameters['need'], equals('calm'));
            expect(options.queryParameters['max_duration'], equals(10));

            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: [
                  {
                    'activity': {
                      'id': 'act-10',
                      'title': 'Calm Mind',
                      'category': 'relaxation',
                      'duration_minutes': 8,
                      'summary': 'Release muscle tension',
                      'steps': ['Step 1', 'Step 2'],
                      'source': 'Wellness Board',
                    },
                    'reason_code': 'FAVORITE',
                  }
                ],
              ),
            );
          },
        ),
      );

      final suggestions =
          await repository.getSuggestions(need: 'calm', maxDuration: 10);
      expect(suggestions.length, 1);
      expect(suggestions.first.reason, ActivitySuggestionReason.favorite);
      expect(suggestions.first.activity.title, 'Calm Mind');
    });

    test('setFavorite issues POST when true and DELETE when false', () async {
      int postCalls = 0;
      int deleteCalls = 0;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.method == 'POST') {
              expect(options.path, equals('/v1/activities/act-1/favorite'));
              postCalls++;
            } else if (options.method == 'DELETE') {
              expect(options.path, equals('/v1/activities/act-1/favorite'));
              deleteCalls++;
            }
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{},
              ),
            );
          },
        ),
      );

      final addResult =
          await repository.setFavorite(activityId: 'act-1', isFavorite: true);
      expect(addResult, isTrue);
      expect(postCalls, 1);

      final delResult =
          await repository.setFavorite(activityId: 'act-1', isFavorite: false);
      expect(delResult, isFalse);
      expect(deleteCalls, 1);
    });

    test('completeActivity posts client_id and optional rating', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, equals('/v1/activities/act-1/complete'));
            final data = options.data as Map<String, dynamic>;
            expect(data['client_id'], equals('cid-12345'));
            expect(data['helpfulness_rating'], equals(4));

            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'log-99',
                  'client_id': 'cid-12345',
                  'activity_id': 'act-1',
                  'activity_title': 'Box Breathing',
                  'category': 'breathing',
                  'completed_at': '2026-10-24T12:00:00Z',
                  'helpfulness_rating': 4,
                },
              ),
            );
          },
        ),
      );

      final log = await repository.completeActivity(
        clientId: 'cid-12345',
        activityId: 'act-1',
        helpfulnessRating: 4,
      );

      expect(log.id, 'log-99');
      expect(log.clientId, 'cid-12345');
      expect(log.helpfulnessRating, 4);
    });

    test('getActivityHistory retrieves paginated history', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, equals('/v1/me/activities/history'));
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'items': [
                    {
                      'id': 'log-1',
                      'client_id': 'cid-1',
                      'activity_id': 'act-1',
                      'activity_title': 'Box Breathing',
                      'category': 'breathing',
                      'completed_at': '2026-10-24T12:00:00Z',
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

      final history = await repository.getActivityHistory();
      expect(history.items.length, 1);
      expect(history.items.first.activityTitle, 'Box Breathing');
      expect(history.hasMore, isFalse);
    });
  });
}
