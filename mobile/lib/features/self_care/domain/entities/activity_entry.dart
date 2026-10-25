import 'activity_category.dart';

/// Represents a curated self-care activity returned by the API.
class ActivityEntry {
  final String id;
  final String title;
  final ActivityCategory category;
  final int durationMinutes;
  final String summary;
  final List<String> steps;
  final String source;
  final String? slug;
  final bool isFavorite;

  const ActivityEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.durationMinutes,
    required this.summary,
    required this.steps,
    required this.source,
    this.slug,
    this.isFavorite = false,
  });

  bool get isComfortCategory => category == ActivityCategory.comfort;

  bool get isBreathingActivity {
    if (category == ActivityCategory.breathing) return true;
    final s = slug?.toLowerCase() ?? '';
    return s.contains('breathe') ||
        s.contains('breathing') ||
        s.contains('box');
  }

  ActivityEntry copyWith({
    String? id,
    String? title,
    ActivityCategory? category,
    int? durationMinutes,
    String? summary,
    List<String>? steps,
    String? source,
    String? slug,
    bool? isFavorite,
  }) {
    return ActivityEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      summary: summary ?? this.summary,
      steps: steps ?? this.steps,
      source: source ?? this.source,
      slug: slug ?? this.slug,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory ActivityEntry.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'];
    List<String> parsedSteps = [];
    if (rawSteps is List) {
      parsedSteps = rawSteps.map((s) => s.toString()).toList();
    } else if (json['content'] is String &&
        (json['content'] as String).isNotEmpty) {
      parsedSteps = (json['content'] as String)
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return ActivityEntry(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: ActivityCategory.fromString(json['category'] as String?),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 5,
      summary: (json['summary'] as String?) ??
          (json['description'] as String?) ??
          (json['content'] as String?) ??
          '',
      steps: parsedSteps,
      source: json['source'] as String? ?? '',
      slug: json['slug'] as String?,
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category.apiValue,
      'duration_minutes': durationMinutes,
      'summary': summary,
      'steps': steps,
      'source': source,
      if (slug != null) 'slug': slug,
      'is_favorite': isFavorite,
    };
  }
}
