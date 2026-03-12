import '../../../core/serialization/json_parsing.dart';

String _capitalizeWord(String value) {
  if (value.isEmpty) {
    return value;
  }
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

String formatProgressMeasurementLabel(String value) {
  final normalized = value.replaceAll(RegExp(r'[_-]+'), ' ').trim();
  if (normalized.isEmpty) {
    return 'Measurement';
  }

  return normalized
      .split(RegExp(r'\s+'))
      .where((segment) => segment.isNotEmpty)
      .map((segment) => _capitalizeWord(segment.toLowerCase()))
      .join(' ');
}

String formatProgressAmount(double amount) {
  if (amount.truncateToDouble() == amount) {
    return amount.toStringAsFixed(0);
  }

  return amount
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

class WeightLogEntry {
  const WeightLogEntry({
    required this.id,
    required this.measuredAt,
    required this.weight,
    required this.unit,
    required this.note,
  });

  final String id;
  final DateTime measuredAt;
  final double weight;
  final String unit;
  final String? note;

  String get formattedWeight => '${formatProgressAmount(weight)} $unit';

  factory WeightLogEntry.fromJson(Map<String, dynamic> json) {
    return WeightLogEntry(
      id: json['id'] as String,
      measuredAt: DateTime.parse(json['measured_at'] as String),
      weight: jsonToDouble(json['weight']),
      unit: json['unit'] as String? ?? 'kg',
      note: json['note'] as String?,
    );
  }
}

class MeasurementLogEntry {
  const MeasurementLogEntry({
    required this.id,
    required this.measurementType,
    required this.measuredAt,
    required this.value,
    required this.unit,
    required this.note,
  });

  final String id;
  final String measurementType;
  final DateTime measuredAt;
  final double value;
  final String unit;
  final String? note;

  String get formattedValue => '${formatProgressAmount(value)} $unit';
  String get displayMeasurementType =>
      formatProgressMeasurementLabel(measurementType);

  factory MeasurementLogEntry.fromJson(Map<String, dynamic> json) {
    return MeasurementLogEntry(
      id: json['id'] as String,
      measurementType: json['measurement_type'] as String? ?? '',
      measuredAt: DateTime.parse(json['measured_at'] as String),
      value: jsonToDouble(json['value']),
      unit: json['unit'] as String? ?? '',
      note: json['note'] as String?,
    );
  }
}

class LatestMeasurementSummary {
  const LatestMeasurementSummary({
    required this.measurementType,
    required this.measuredAt,
    required this.value,
    required this.unit,
  });

  final String measurementType;
  final DateTime measuredAt;
  final double value;
  final String unit;

  String get displayMeasurementType =>
      formatProgressMeasurementLabel(measurementType);
  String get formattedValue => '${formatProgressAmount(value)} $unit';

  factory LatestMeasurementSummary.fromJson(Map<String, dynamic> json) {
    return LatestMeasurementSummary(
      measurementType: json['measurement_type'] as String? ?? '',
      measuredAt: DateTime.parse(json['measured_at'] as String),
      value: jsonToDouble(json['value']),
      unit: json['unit'] as String? ?? '',
    );
  }
}

class ProgressGoalSummary {
  const ProgressGoalSummary({
    required this.id,
    required this.code,
    required this.title,
    required this.targetValue,
    required this.targetUnit,
  });

  final String id;
  final String code;
  final String title;
  final double? targetValue;
  final String? targetUnit;

  String? get formattedTarget {
    if (targetValue == null || targetUnit == null || targetUnit!.isEmpty) {
      return null;
    }
    return '${formatProgressAmount(targetValue!)} $targetUnit';
  }

  factory ProgressGoalSummary.fromJson(Map<String, dynamic> json) {
    return ProgressGoalSummary(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? 'Goal',
      targetValue: json['target_value'] == null
          ? null
          : jsonToDouble(json['target_value']),
      targetUnit: json['target_unit'] as String?,
    );
  }
}

class ProgressOverviewData {
  const ProgressOverviewData({
    required this.latestWeight,
    required this.previousWeight,
    required this.weightChange,
    required this.weightChangeUnit,
    required this.latestMeasurements,
    required this.currentGoal,
  });

  final WeightLogEntry? latestWeight;
  final WeightLogEntry? previousWeight;
  final double? weightChange;
  final String? weightChangeUnit;
  final List<LatestMeasurementSummary> latestMeasurements;
  final ProgressGoalSummary? currentGoal;

  bool get isEmpty =>
      latestWeight == null &&
      latestMeasurements.isEmpty &&
      currentGoal == null;

  String? get weightChangeLabel {
    if (weightChange == null || weightChangeUnit == null) {
      return null;
    }

    if (weightChange == 0) {
      return 'No change vs previous entry';
    }

    final direction = weightChange! < 0 ? 'down' : 'up';
    return '${formatProgressAmount(weightChange!.abs())} '
        '$weightChangeUnit $direction vs previous';
  }

  factory ProgressOverviewData.fromJson(Map<String, dynamic> json) {
    final latestMeasurementsJson =
        json['latest_measurements'] as List<dynamic>? ?? const [];

    return ProgressOverviewData(
      latestWeight: json['latest_weight'] == null
          ? null
          : WeightLogEntry.fromJson(
              json['latest_weight'] as Map<String, dynamic>,
            ),
      previousWeight: json['previous_weight'] == null
          ? null
          : WeightLogEntry.fromJson(
              json['previous_weight'] as Map<String, dynamic>,
            ),
      weightChange: json['weight_change'] == null
          ? null
          : jsonToDouble(json['weight_change']),
      weightChangeUnit: json['weight_change_unit'] as String?,
      latestMeasurements: latestMeasurementsJson
          .map(
            (item) => LatestMeasurementSummary.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      currentGoal: json['current_goal'] == null
          ? null
          : ProgressGoalSummary.fromJson(
              json['current_goal'] as Map<String, dynamic>,
            ),
    );
  }
}
