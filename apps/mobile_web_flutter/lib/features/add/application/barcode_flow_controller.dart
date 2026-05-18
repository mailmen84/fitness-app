import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/meal_logging_models.dart';
import '../infrastructure/barcode_repository.dart';

/// High-level outcome of looking up a barcode. The UI uses this to decide
/// whether to navigate to the food detail screen, the review form, or to show
/// an error.
enum BarcodeLookupKind {
  idle,
  loading,
  foundLocal,
  foundOpenFoodFacts,
  notFound,
  error,
}

class BarcodeLookupResult {
  const BarcodeLookupResult({
    required this.kind,
    this.barcode,
    this.localFood,
    this.draft,
    this.errorMessage,
  });

  final BarcodeLookupKind kind;
  final String? barcode;
  final FoodDetail? localFood;
  final OpenFoodFactsDraft? draft;
  final String? errorMessage;

  static const idle = BarcodeLookupResult(kind: BarcodeLookupKind.idle);
  static const loading = BarcodeLookupResult(kind: BarcodeLookupKind.loading);
}

class BarcodeFlowController extends Notifier<BarcodeLookupResult> {
  late final BarcodeRepository _repository;

  @override
  BarcodeLookupResult build() {
    _repository = ref.watch(barcodeRepositoryProvider);
    return BarcodeLookupResult.idle;
  }

  /// Resets state. Call when leaving the scanner so a stale result does not
  /// pop up if the user re-enters.
  void reset() {
    state = BarcodeLookupResult.idle;
  }

  /// Looks up [barcode] locally first, then in OpenFoodFacts. Updates state
  /// for every step so the UI can react.
  Future<BarcodeLookupResult> lookup(String barcode) async {
    final normalized = barcode.trim();
    if (normalized.isEmpty) {
      final result = BarcodeLookupResult(
        kind: BarcodeLookupKind.error,
        barcode: normalized,
        errorMessage: 'Empty barcode.',
      );
      state = result;
      return result;
    }

    state = BarcodeLookupResult.loading;

    try {
      final local = await _repository.findByBarcode(normalized);
      if (local != null) {
        final result = BarcodeLookupResult(
          kind: BarcodeLookupKind.foundLocal,
          barcode: normalized,
          localFood: local,
        );
        state = result;
        return result;
      }
    } catch (error) {
      final result = BarcodeLookupResult(
        kind: BarcodeLookupKind.error,
        barcode: normalized,
        errorMessage: _normalizeError(error),
      );
      state = result;
      return result;
    }

    try {
      final draft = await _repository.lookupOpenFoodFacts(normalized);
      if (draft.found) {
        final result = BarcodeLookupResult(
          kind: BarcodeLookupKind.foundOpenFoodFacts,
          barcode: normalized,
          draft: draft,
        );
        state = result;
        return result;
      }
      final result = BarcodeLookupResult(
        kind: BarcodeLookupKind.notFound,
        barcode: normalized,
        draft: draft,
      );
      state = result;
      return result;
    } catch (error) {
      final result = BarcodeLookupResult(
        kind: BarcodeLookupKind.error,
        barcode: normalized,
        errorMessage: _normalizeError(error),
      );
      state = result;
      return result;
    }
  }

  /// Saves a reviewed draft as a new local food. Caller passes the values
  /// from the form; this just delegates to the repository.
  Future<FoodDetail> saveReviewedFood({
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
  }) {
    return _repository.createFood(
      name: name,
      brand: brand,
      barcode: barcode,
      defaultServingAmount: defaultServingAmount,
      defaultServingUnit: defaultServingUnit,
      source: source,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }

  String _normalizeError(Object error) {
    final message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }
}

final barcodeFlowControllerProvider =
    NotifierProvider<BarcodeFlowController, BarcodeLookupResult>(
  BarcodeFlowController.new,
);
