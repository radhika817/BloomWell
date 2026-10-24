/// Supported symptom types for CycleCare logging.
enum CycleSymptomType {
  cramps('cramps'),
  bloating('bloating'),
  fatigue('fatigue'),
  headache('headache'),
  backPain('back_pain'),
  breastTenderness('breast_tenderness'),
  nausea('nausea'),
  moodChanges('mood_changes'),
  acne('acne'),
  cravings('cravings'),
  sleepTrouble('sleep_trouble'),
  other('other');

  const CycleSymptomType(this.apiValue);
  final String apiValue;

  static CycleSymptomType fromString(String val) {
    for (final type in CycleSymptomType.values) {
      if (type.apiValue == val || type.name == val) {
        return type;
      }
    }
    return CycleSymptomType.other;
  }
}

/// Domain entity representing a logged cycle symptom record.
class CycleSymptomEntry {
  const CycleSymptomEntry({
    required this.id,
    required this.clientId,
    required this.date,
    required this.symptomType,
    this.customLabel,
    required this.severity,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clientId;

  /// Local date string in format YYYY-MM-DD
  final String date;

  final CycleSymptomType symptomType;

  /// Custom label (max 40 characters), used only when symptomType == other
  final String? customLabel;

  /// Severity score from 1 (barely noticeable) to 5 (very strong)
  final int severity;

  /// Optional notes (max 500 characters)
  final String? notes;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CycleSymptomEntry.fromJson(Map<String, dynamic> json) {
    return CycleSymptomEntry(
      id: json['id'] as String,
      clientId: json['client_id'] as String? ?? json['id'] as String,
      date: json['date'] as String,
      symptomType: CycleSymptomType.fromString(
          json['symptom_type'] as String? ?? 'other'),
      customLabel: json['custom_label'] as String?,
      severity: (json['severity'] as num?)?.toInt() ?? 3,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'date': date,
      'symptom_type': symptomType.apiValue,
      if (customLabel != null && customLabel!.trim().isNotEmpty)
        'custom_label': customLabel!.trim(),
      'severity': severity,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  CycleSymptomEntry copyWith({
    String? id,
    String? clientId,
    String? date,
    CycleSymptomType? symptomType,
    String? Function()? customLabel,
    int? severity,
    String? Function()? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CycleSymptomEntry(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      date: date ?? this.date,
      symptomType: symptomType ?? this.symptomType,
      customLabel: customLabel != null ? customLabel() : this.customLabel,
      severity: severity ?? this.severity,
      notes: notes != null ? notes() : this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
