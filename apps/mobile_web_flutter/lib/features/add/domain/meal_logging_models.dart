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
    required this.barcode,
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
  final String? barcode;
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
      barcode: json['barcode'] as String?,
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
    required this.barcode,
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
  final String? barcode;
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
      barcode: json['barcode'] as String?,
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

/// Draft returned from the OpenFoodFacts lookup endpoint. The UI uses this
/// to prefill the review form. Any of the macro fields can be null when OFF
/// does not provide that nutriment.
class OpenFoodFactsDraft {
  const OpenFoodFactsDraft({
    required this.barcode,
    required this.found,
    required this.isComplete,
    required this.name,
    required this.brand,
    required this.defaultServingAmount,
    required this.defaultServingUnit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.imageUrl,
    required this.sourceUrl,
  });

  final String barcode;
  final bool found;
  final bool isComplete;
  final String? name;
  final String? brand;
  final double? defaultServingAmount;
  final String? defaultServingUnit;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String? imageUrl;
  final String? sourceUrl;

  bool get hasMissingMacros => !isComplete && found;

  factory OpenFoodFactsDraft.fromJson(Map<String, dynamic> json) {
    double? readDouble(Object? value) {
      if (value == null) return null;
      return jsonToDouble(value);
    }

    return OpenFoodFactsDraft(
      barcode: json['barcode'] as String? ?? '',
      found: json['found'] as bool? ?? false,
      isComplete: json['is_complete'] as bool? ?? false,
      name: json['name'] as String?,
      brand: json['brand'] as String?,
      defaultServingAmount: readDouble(json['default_serving_amount']),
      defaultServingUnit: json['default_serving_unit'] as String?,
      calories: readDouble(json['calories']),
      protein: readDouble(json['protein']),
      carbs: readDouble(json['carbs']),
      fat: readDouble(json['fat']),
      imageUrl: json['image_url'] as String?,
      sourceUrl: json['source_url'] as String?,
    );
  }
}
