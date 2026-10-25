import 'package:bloomwell/core/api/api_client.dart';
import 'package:bloomwell/features/exams/data/academic_events_repository.dart';
import 'package:bloomwell/features/exams/domain/entities/academic_event_type.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AcademicEventsRepository Unit Tests', () {
    late Dio dio;
    late ApiClient apiClient;
    late AcademicEventsRepository repository;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000'));
      apiClient = ApiClient(dio: dio);
      repository = AcademicEventsRepository(apiClient: apiClient);
    });

    test('getEvents queries academic events with pagination', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, equals('/v1/academic-events'));
            expect(options.queryParameters['upcoming_only'], equals(true));

            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'items': [
                    {
                      'id': 'ev-1',
                      'client_id': 'cid-1',
                      'title': 'Biochemistry Midterm',
                      'event_date': '2026-11-15',
                      'event_type': 'exam',
                      'created_at': '2026-10-24T10:00:00Z',
                    }
                  ],
                  'next_cursor': 'cur_next',
                  'has_more': true,
                },
              ),
            );
          },
        ),
      );

      final result = await repository.getEvents(upcomingOnly: true);
      expect(result.items.length, 1);
      expect(result.items.first.title, 'Biochemistry Midterm');
      expect(result.items.first.eventType, AcademicEventType.exam);
      expect(result.nextCursor, 'cur_next');
      expect(result.hasMore, isTrue);
    });

    test('createEvent posts client_id, formatted date, and type', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, equals('/v1/academic-events'));
            final data = options.data as Map<String, dynamic>;
            expect(data['client_id'], equals('cid-random-uuid'));
            expect(data['title'], equals('Final Presentation'));
            expect(data['event_date'], equals('2026-12-05'));
            expect(data['event_type'], equals('presentation'));

            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'id': 'ev-created',
                  'client_id': 'cid-random-uuid',
                  'title': 'Final Presentation',
                  'event_date': '2026-12-05',
                  'event_type': 'presentation',
                  'created_at': '2026-10-24T12:00:00Z',
                },
              ),
            );
          },
        ),
      );

      final event = await repository.createEvent(
        clientId: 'cid-random-uuid',
        title: 'Final Presentation',
        eventDate: DateTime(2026, 12, 5),
        eventType: AcademicEventType.presentation,
      );

      expect(event.id, 'ev-created');
      expect(event.title, 'Final Presentation');
      expect(event.eventType, AcademicEventType.presentation);
    });

    test('updateEvent sends patch payload', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, equals('/v1/academic-events/ev-1'));
            final data = options.data as Map<String, dynamic>;
            expect(data['title'], equals('Updated Title'));

            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'ev-1',
                  'client_id': 'cid-1',
                  'title': 'Updated Title',
                  'event_date': '2026-11-15',
                  'event_type': 'exam',
                  'created_at': '2026-10-24T10:00:00Z',
                },
              ),
            );
          },
        ),
      );

      final updated = await repository.updateEvent(
        id: 'ev-1',
        title: 'Updated Title',
      );
      expect(updated.title, 'Updated Title');
    });

    test('deleteEvent issues DELETE call', () async {
      int deleteCalls = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, equals('DELETE'));
            expect(options.path, equals('/v1/academic-events/ev-del'));
            deleteCalls++;
            return handler.resolve(
              Response(requestOptions: options, statusCode: 204),
            );
          },
        ),
      );

      await repository.deleteEvent('ev-del');
      expect(deleteCalls, 1);
    });
  });
}
