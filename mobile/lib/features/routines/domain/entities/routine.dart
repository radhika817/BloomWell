import 'routine_item.dart';

/// Represents a personal wellness routine created by a student.
class Routine {
  final String id;
  final String title;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<RoutineItem> items;
  final DateTime createdAt;

  const Routine({
    required this.id,
    required this.title,
    this.startDate,
    this.endDate,
    this.items = const [],
    required this.createdAt,
  });

  int get completedItemsCount => items.where((item) => item.isDone).length;
  int get totalItemsCount => items.length;

  /// Plain non-judgmental progress string (e.g. "3 of 5 done").
  /// Strictly no streaks, no percentage rings, and no celebratory consistency tracking.
  String get progressText => '$completedItemsCount of $totalItemsCount done';

  Routine copyWith({
    String? id,
    String? title,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    List<RoutineItem>? items,
    DateTime? createdAt,
  }) {
    return Routine(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Routine.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return Routine(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      items: rawItems
          .map((i) => RoutineItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (startDate != null)
        'start_date':
            '${startDate!.year.toString().padLeft(4, '0')}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}',
      if (endDate != null)
        'end_date':
            '${endDate!.year.toString().padLeft(4, '0')}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}',
      'items': items.map((i) => i.toJson()).toList(),
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
