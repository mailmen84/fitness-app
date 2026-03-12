import 'package:flutter/material.dart';

import '../../../core/serialization/json_parsing.dart';

enum TodayMealSectionCode {
  breakfast(
    title: 'Breakfast',
    icon: Icons.breakfast_dining_rounded,
  ),
  lunch(
    title: 'Lunch',
    icon: Icons.lunch_dining_rounded,
  ),
  dinner(
    title: 'Dinner',
    icon: Icons.dinner_dining_rounded,
  ),
  snacks(
    title: 'Snacks',
    icon: Icons.icecream_rounded,
  );

  const TodayMealSectionCode({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  String get apiValue => name;

  static TodayMealSectionCode fromApi(String value) {
    return TodayMealSectionCode.values.firstWhere(
      (section) => section.apiValue == value,
      orElse: () => TodayMealSectionCode.snacks,
    );
  }
}

String _formatQuantity(double quantity) {
  if (quantity.truncateToDouble() == quantity) {
    return quantity.toStringAsFixed(0);
  }
  return quantity
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

class TodayMealEntry {
  const TodayMealEntry({
    required this.id,
    required this.mealId,
    required this.foodId,
    required this.foodName,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.notes,
  });

  final String id;
  final String mealId;
  final String? foodId;
  final String foodName;
  final double quantity;
  final String unit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? notes;

  String get title => foodName;
  String get quantityLabel => '${_formatQuantity(quantity)} $unit';

  factory TodayMealEntry.fromJson(Map<String, dynamic> json) {
    return TodayMealEntry(
      id: json['id'] as String,
      mealId: json['meal_id'] as String,
      foodId: json['food_id'] as String?,
      foodName: json['food_name'] as String? ?? 'Food item',
      quantity: jsonToDouble(json['quantity']),
      unit: json['unit'] as String? ?? 'serving',
      calories: jsonToDouble(json['calories']),
      protein: jsonToDouble(json['protein']),
      carbs: jsonToDouble(json['carbs']),
      fat: jsonToDouble(json['fat']),
      notes: json['notes'] as String?,
    );
  }
}

class TodayMealSection {
  const TodayMealSection({
    required this.code,
    required this.caloriesTotal,
    required this.proteinTotal,
    required this.carbsTotal,
    required this.fatTotal,
    required this.entries,
  });

  const TodayMealSection.empty(this.code)
      : caloriesTotal = 0,
        proteinTotal = 0,
        carbsTotal = 0,
        fatTotal = 0,
        entries = const [];

  final TodayMealSectionCode code;
  final double caloriesTotal;
  final double proteinTotal;
  final double carbsTotal;
  final double fatTotal;
  final List<TodayMealEntry> entries;

  String get title => code.title;
  IconData get icon => code.icon;
  bool get isEmpty => entries.isEmpty;

  factory TodayMealSection.fromJson(Map<String, dynamic> json) {
    final entriesJson = json['entries'] as List<dynamic>? ?? const [];
    return TodayMealSection(
      code: TodayMealSectionCode.fromApi(
        json['code'] as String? ?? 'snacks',
      ),
      caloriesTotal: jsonToDouble(json['calories_total']),
      proteinTotal: jsonToDouble(json['protein_total']),
      carbsTotal: jsonToDouble(json['carbs_total']),
      fatTotal: jsonToDouble(json['fat_total']),
      entries: entriesJson
          .map((item) => TodayMealEntry.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class TodayDashboardData {
  const TodayDashboardData({
    required this.date,
    required this.caloriesTotal,
    required this.proteinTotal,
    required this.carbsTotal,
    required this.fatTotal,
    required this.mealSections,
  });

  final DateTime date;
  final double caloriesTotal;
  final double proteinTotal;
  final double carbsTotal;
  final double fatTotal;
  final List<TodayMealSection> mealSections;

  bool get isEmpty => mealSections.every((section) => section.entries.isEmpty);

  factory TodayDashboardData.empty(DateTime date) {
    final normalizedDate = DateUtils.dateOnly(date);
    return TodayDashboardData(
      date: normalizedDate,
      caloriesTotal: 0,
      proteinTotal: 0,
      carbsTotal: 0,
      fatTotal: 0,
      mealSections: const [
        TodayMealSection.empty(TodayMealSectionCode.breakfast),
        TodayMealSection.empty(TodayMealSectionCode.lunch),
        TodayMealSection.empty(TodayMealSectionCode.dinner),
        TodayMealSection.empty(TodayMealSectionCode.snacks),
      ],
    );
  }

  factory TodayDashboardData.fromJson(Map<String, dynamic> json) {
    final sectionsJson = json['meal_sections'] as List<dynamic>? ?? const [];
    return TodayDashboardData(
      date: DateTime.parse(json['date'] as String),
      caloriesTotal: jsonToDouble(json['calories_total']),
      proteinTotal: jsonToDouble(json['protein_total']),
      carbsTotal: jsonToDouble(json['carbs_total']),
      fatTotal: jsonToDouble(json['fat_total']),
      mealSections: sectionsJson
          .map((item) => TodayMealSection.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}