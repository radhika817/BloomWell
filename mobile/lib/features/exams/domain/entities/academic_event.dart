import 'academic_event_type.dart';

/// Represents an entered exam, assignment, or deadline.
class AcademicEvent {
  final String id;
  final String clientId;
  final String title;
  final DateTime eventDate; // Date in local calendar
  final AcademicEventType eventType;
  final DateTime createdAt;

  const AcademicEvent({
    required this.id,
    required this.clientId,
    required this.title,
    required this.eventDate,
    required this.eventType,
    required this.createdAt,
  });

  /// True if the event date is strictly before today's local date.
  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
    return eventDay.isBefore(today);
  }

  /// Calculates day difference between eventDate and today.
  /// Positive for future events ("in X days"), negative for past ("X days ago"), 0 for today.
  int get daysDifferenceFromToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
    return eventDay.difference(today).inDays;
  }

  AcademicEvent copyWith({
    String? id,
    String? clientId,
    String? title,
    DateTime? eventDate,
    AcademicEventType? eventType,
    DateTime? createdAt,
  }) {
    return AcademicEvent(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      title: title ?? this.title,
      eventDate: eventDate ?? this.eventDate,
      eventType: eventType ?? this.eventType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AcademicEvent.fromJson(Map<String, dynamic> json) {
    return AcademicEvent(
      id: json['id'] as String? ?? '',
      clientId: json['client_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      eventDate: json['event_date'] != null
          ? DateTime.parse(json['event_date'] as String)
          : DateTime.now(),
      eventType: AcademicEventType.fromString(json['event_type'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'title': title,
      'event_date':
          '${eventDate.year.toString().padLeft(4, '0')}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}',
      'event_type': eventType.apiValue,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
