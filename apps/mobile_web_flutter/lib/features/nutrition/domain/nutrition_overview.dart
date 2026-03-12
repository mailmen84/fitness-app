import '../../../core/serialization/json_parsing.dart';

enum NutritionRangeOption {
  day('day', 'Day'),
  week('week', 'Week'),
  month('month', 'Month');

  const NutritionRangeOption(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static NutritionRangeOption fromApi(String? value) {
    return NutritionRangeOption.values.firstWhere(
      (range) => range.apiValue == value,
      orElse: () => NutritionRangeOption.day,
    );
  }
}

enum NutritionMetricType {
  calories('calories', 'Calories', 'kcal'),
  protein('protein', 'Protein', 'g'),
  carbs('carbs', 'Carbs', 'g'),
  fat('fat', 'Fat', 'g');

  const NutritionMetricType(this.apiValue, this.label, this.unit);

  final String apiValue;
  final String label;
  final String unit;

  static NutritionMetricType fromApi(String? value) {
    return NutritionMetricType.values.firstWhere(
      (metric) => metric.apiValue == value,
      orElse: () => NutritionMetricType.calories,
    );
  }
}

String _formatAmount(double amount) {
  if (amount.truncateToDouble() == amount) {
    return amount.toStringAsFixed(0);
  }
  return amount
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _mealSectionTitle(String code) {
  return switch (code) {
    'breakfast' => 'Breakfast',
    'lunch' => 'Lunch',
    'dinner' => 'Dinner',
    'snacks' => 'Snacks',
    _ => 'Meal',
  };
}

class NutritionTargets {
  const NutritionTargets({
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
  });

  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;

  double? targetForMetric(NutritionMetricType metricType) {
    return switch (metricType) {
      NutritionMetricType.calories => calories,
      NutritionMetricType.protein => protein,
      NutritionMetricType.carbs => carbs,
      NutritionMetricType.fat => fat,
    };
  }

  factory NutritionTargets.fromJson(Map<String, dynamic> json) {
    return NutritionTargets(
      calories: json['calories'] == null ? null : jsonToDouble(json['calories']),
      protein: json['protein'] == null ? null : jsonToDouble(json['protein']),
      carbs: json['carbs'] == null ? null : jsonToDouble(json['carbs']),
      fat: json['fat'] == null ? null : jsonToDouble(json['fat']),
    );
  }
}

class NutritionCategoryRow {
  const NutritionCategoryRow({
    required this.code,
    required this.title,
    required this.amount,
    required this.unit,
    required this.target,
    required this.progressRatio,
  });

  final NutritionMetricType code;
  final String title;
  final double amount;
  final String unit;
  final double? target;
  final double? progressRatio;

  bool get hasTarget => target != null && target! > 0;

  factory NutritionCategoryRow.fromJson(Map<String, dynamic> json) {
    return NutritionCategoryRow(
      code: NutritionMetricType.fromApi(json['code'] as String?),
      title: json['title'] as String? ?? 'Metric',
      amount: jsonToDouble(json['amount']),
      unit: json['unit'] as String? ?? '',
      target: json['target'] == null ? null : jsonToDouble(json['target']),
      progressRatio: json['progress_ratio'] == null
          ? null
          : jsonToDouble(json['progress_ratio']),
    );
  }
}

class NutritionContributor {
  const NutritionContributor({
    required this.entryId,
    required this.mealId,
    required this.mealSectionCode,
    required this.foodName,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final String entryId;
  final String mealId;
  final String mealSectionCode;
  final String foodName;
  final double quantity;
  final String unit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  String get mealSectionTitle => _mealSectionTitle(mealSectionCode);
  String get quantityLabel => '${_formatAmount(quantity)} $unit';

  factory NutritionContributor.fromJson(Map<String, dynamic> json) {
    return NutritionContributor(
      entryId: json['entry_id'] as String,
      mealId: json['meal_id'] as String,
      mealSectionCode: json['meal_section'] as String? ?? 'snacks',
      foodName: json['food_name'] as String? ?? 'Food item',
      quantity: jsonToDouble(json['quantity']),
      unit: json['unit'] as String? ?? 'serving',
      calories: jsonToDouble(json['calories']),
      protein: jsonToDouble(json['protein']),
      carbs: jsonToDouble(json['carbs']),
      fat: jsonToDouble(json['fat']),
    );
  }
}

class NutritionMacroContributor {
  const NutritionMacroContributor({
    required this.entryId,
    required this.mealId,
    required this.mealSectionCode,
    required this.foodName,
    required this.quantity,
    required this.unit,
    required this.value,
    required this.shareRatio,
  });

  final String entryId;
  final String mealId;
  final String mealSectionCode;
  final String foodName;
  final double quantity;
  final String unit;
  final double value;
  final double? shareRatio;

  factory NutritionMacroContributor.fromJson(Map<String, dynamic> json) {
    return NutritionMacroContributor(
      entryId: json['entry_id'] as String,
      mealId: json['meal_id'] as String,
      mealSectionCode: json['meal_section'] as String? ?? 'snacks',
      foodName: json['food_name'] as String? ?? 'Food item',
      quantity: jsonToDouble(json['quantity']),
      unit: json['unit'] as String? ?? 'serving',
      value: jsonToDouble(json['value']),
      shareRatio: json['share_ratio'] == null
          ? null
          : jsonToDouble(json['share_ratio']),
    );
  }
}

class NutritionMacroDetail {
  const NutritionMacroDetail({
    required this.macroType,
    required this.range,
    required this.anchorDate,
    required this.periodStart,
    required this.periodEnd,
    required this.total,
    required this.unit,
    required this.target,
    required this.contributors,
  });

  final NutritionMetricType macroType;
  final NutritionRangeOption range;
  final DateTime anchorDate;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double total;
  final String unit;
  final double? target;
  final List<NutritionMacroContributor> contributors;

  factory NutritionMacroDetail.fromJson(Map<String, dynamic> json) {
    final contributorsJson = json['contributors'] as List<dynamic>? ?? const [];
    return NutritionMacroDetail(
      macroType: NutritionMetricType.fromApi(json['macro_type'] as String?),
      range: NutritionRangeOption.fromApi(json['range'] as String?),
      anchorDate: DateTime.parse(json['anchor_date'] as String),
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      total: jsonToDouble(json['total']),
      unit: json['unit'] as String? ?? '',
      target: json['target'] == null ? null : jsonToDouble(json['target']),
      contributors: contributorsJson
          .map(
            (item) =>
                NutritionMacroContributor.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }
}

class NutritionOverviewData {
  const NutritionOverviewData({
    required this.range,
    required this.anchorDate,
    required this.periodStart,
    required this.periodEnd,
    required this.caloriesTotal,
    required this.proteinTotal,
    required this.carbsTotal,
    required this.fatTotal,
    required this.targets,
    required this.categoryRows,
    required this.topContributors,
  });

  final NutritionRangeOption range;
  final DateTime anchorDate;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double caloriesTotal;
  final double proteinTotal;
  final double carbsTotal;
  final double fatTotal;
  final NutritionTargets targets;
  final List<NutritionCategoryRow> categoryRows;
  final List<NutritionContributor> topContributors;

  bool get isEmpty =>
      caloriesTotal <= 0 &&
      proteinTotal <= 0 &&
      carbsTotal <= 0 &&
      fatTotal <= 0 &&
      topContributors.isEmpty;

  factory NutritionOverviewData.fromJson(Map<String, dynamic> json) {
    final categoryRowsJson = json['category_rows'] as List<dynamic>? ?? const [];
    final contributorsJson =
        json['top_contributors'] as List<dynamic>? ?? const [];

    return NutritionOverviewData(
      range: NutritionRangeOption.fromApi(json['range'] as String?),
      anchorDate: DateTime.parse(json['anchor_date'] as String),
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      caloriesTotal: jsonToDouble(json['calories_total']),
      proteinTotal: jsonToDouble(json['protein_total']),
      carbsTotal: jsonToDouble(json['carbs_total']),
      fatTotal: jsonToDouble(json['fat_total']),
      targets: NutritionTargets.fromJson(
        json['targets'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      categoryRows: categoryRowsJson
          .map((item) => NutritionCategoryRow.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      topContributors: contributorsJson
          .map((item) => NutritionContributor.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

