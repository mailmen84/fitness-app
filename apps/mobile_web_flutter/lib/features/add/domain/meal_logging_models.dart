import '../../../core/serialization/json_parsing.dart';

String _formatServingAmount(double amount) {
  if (amount.truncateToDouble() == amount) {
    return amount.toStringAsFixed(0);
  }
  return amount.toStringAsFixed(2);
}

double _normalizedServingAmount(Object? value) {
  final servingAmount = jsonToDouble(value);
  return servingAmount == 0 ? 1 : servingAmount;
}

class FoodSearchResult {
  const FoodSearchResult({
    required this.id,
    required this.name,
    required this.brand,
    required this.defaultServingAmount,
    required this.defaultServingUnit,
    required this.isVerified,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final String id;
  final String name;
  final String? brand;
  final double defaultServingAmount;
  final String defaultServingUnit;
  final bool isVerified;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  String get servingLabel =>
      '${_formatServingAmount(defaultServingAmount)} $defaultServingUnit';

  factory FoodSearchResult.fromJson(Map<String, dynamic> json) {
    return FoodSearchResult(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Food item',
      brand: json['brand'] as String?,
      defaultServingAmount: _normalizedServingAmount(json['default_serving_amount']),
      defaultServingUnit: json['default_serving_unit'] as String? ?? 'serving',
      isVerified: json['is_verified'] as bool? ?? false,
      calories: jsonToDouble(json['calories']),
      protein: jsonToDouble(json['protein']),
      carbs: jsonToDouble(json['carbs']),
      fat: jsonToDouble(json['fat']),
    );
  }
}

class FoodNutrient {
  const FoodNutrient({
    required this.code,
    required this.name,
    required this.amount,
    required this.unit,
  });

  final String code;
  final String name;
  final double amount;
  final String unit;

  factory FoodNutrient.fromJson(Map<String, dynamic> json) {
    return FoodNutrient(
      code: json['nutrient_code'] as String? ?? '',
      name: json['nutrient_name'] as String? ?? '',
      amount: jsonToDouble(json['amount']),
      unit: json['unit'] as String? ?? '',
    );
  }
}

class FoodDetail {
  const FoodDetail({
    required this.id,
    required this.name,
    required this.brand,
    required this.defaultServingAmount,
    required this.defaultServingUnit,
    required this.isVerified,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.nutrients,
  });

  final String id;
  final String name;
  final String? brand;
  final double defaultServingAmount;
  final String defaultServingUnit;
  final bool isVerified;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final List<FoodNutrient> nutrients;

  String get servingLabel =>
      '${_formatServingAmount(defaultServingAmount)} $defaultServingUnit';

  factory FoodDetail.fromJson(Map<String, dynamic> json) {
    final nutrientsJson = json['nutrients'] as List<dynamic>? ?? const [];
    return FoodDetail(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Food item',
      brand: json['brand'] as String?,
      defaultServingAmount: _normalizedServingAmount(json['default_serving_amount']),
      defaultServingUnit: json['default_serving_unit'] as String? ?? 'serving',
      isVerified: json['is_verified'] as bool? ?? false,
      calories: jsonToDouble(json['calories']),
      protein: jsonToDouble(json['protein']),
      carbs: jsonToDouble(json['carbs']),
      fat: jsonToDouble(json['fat']),
      nutrients: nutrientsJson
          .map((item) => FoodNutrient.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
