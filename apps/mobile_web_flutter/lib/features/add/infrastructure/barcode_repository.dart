import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_api_client.dart';
import '../../shared/application/api_client_provider.dart';
import '../domain/meal_logging_models.dart';

class BarcodeConflictException implements Exception {
  const BarcodeConflictException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class BarcodeRepository {
  /// Returns the local food matching the barcode, or null when nothing is
  /// stored yet. Distinct from [lookupOpenFoodFacts], which talks to OFF.
  Future<FoodDetail?> findByBarcode(String barcode);

  /// Asks the backend to consult OpenFoodFacts and return a draft for review.
  /// Always returns a draft; check [OpenFoodFactsDraft.found] before using it.
  Future<OpenFoodFactsDraft> lookupOpenFoodFacts(String barcode);

  /// Persists a new food (custom or imported from OFF). Throws
  /// [BarcodeConflictException] when the barcode already exists in the DB.
  Future<FoodDetail> createFood({
    required String name,
    String? brand,
    String? barcode,
    double? defaultServingAmount,
    String? defaultServingUnit,
    required String source,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
  });
}

class ApiBarcodeRepository implements BarcodeRepository {
  const ApiBarcodeRepository({required this.apiClient});

  final AppApiClient apiClient;

  @override
  Future<FoodDetail?> findByBarcode(String barcode) async {
    try {
      final payload = await apiClient.getMap('/foods/by-barcode/$barcode');
      return FoodDetail.fromJson(payload);
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<OpenFoodFactsDraft> lookupOpenFoodFacts(String barcode) async {
    final payload = await apiClient.getMap('/foods/openfoodfacts/$barcode');
    return OpenFoodFactsDraft.fromJson(payload);
  }

  @override
  Future<FoodDetail> createFood({
    required String name,
    String? brand,
    String? barcode,
    double? defaultServingAmount,
    String? defaultServingUnit,
    required String source,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    try {
      final payload = await apiClient.postJsonMap(
        '/foods',
        body: {
          'name': name,
          if (brand != null && brand.trim().isNotEmpty) 'brand': brand.trim(),
          if (barcode != null && barcode.trim().isNotEmpty) 'barcode': barcode.trim(),
          if (defaultServingAmount != null)
            'default_serving_amount': defaultServingAmount,
          if (defaultServingUnit != null && defaultServingUnit.trim().isNotEmpty)
            'default_serving_unit': defaultServingUnit.trim(),
          'source': source,
          'calories': calories,
          'protein': protein,
          'carbs': carbs,
          'fat': fat,
        },
      );
      return FoodDetail.fromJson(payload);
    } on ApiException catch (error) {
      if (error.statusCode == 409) {
        throw BarcodeConflictException(
          error.message.isEmpty
              ? 'A food with this barcode already exists.'
              : error.message,
        );
      }
      rethrow;
    }
  }
}

final barcodeRepositoryProvider = Provider<BarcodeRepository>((ref) {
  final apiClient = ref.watch(appApiClientProvider);
  return ApiBarcodeRepository(apiClient: apiClient);
});
