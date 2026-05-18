import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/app_api_client.dart';
import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../application/barcode_flow_controller.dart';
import '../domain/meal_logging_models.dart';
import '../infrastructure/barcode_repository.dart';

/// Review/edit screen used after a barcode scan. Prefilled from OpenFoodFacts
/// when available, otherwise empty (and only the barcode is read-only).
/// On save, creates the food in the local DB and routes to the food detail
/// screen so the user can immediately add it to a meal.
class BarcodeReviewScreen extends ConsumerStatefulWidget {
  const BarcodeReviewScreen({required this.barcode, super.key});

  final String barcode;

  @override
  ConsumerState<BarcodeReviewScreen> createState() =>
      _BarcodeReviewScreenState();
}

class _BarcodeReviewScreenState extends ConsumerState<BarcodeReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _servingAmountController = TextEditingController();
  final _servingUnitController = TextEditingController(text: 'g');
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  bool _initialized = false;
  bool _isSubmitting = false;
  String? _submitError;
  OpenFoodFactsDraft? _draft;

  @override
  void initState() {
    super.initState();
    final lookup = ref.read(barcodeFlowControllerProvider);
    if (lookup.barcode == widget.barcode && lookup.draft != null) {
      _seedFromDraft(lookup.draft!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _servingAmountController.dispose();
    _servingUnitController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _seedFromDraft(OpenFoodFactsDraft draft) {
    _draft = draft;
    if (draft.name != null) _nameController.text = draft.name!;
    if (draft.brand != null) _brandController.text = draft.brand!;
    if (draft.defaultServingAmount != null) {
      _servingAmountController.text = _formatNumber(draft.defaultServingAmount!);
    }
    if (draft.defaultServingUnit != null) {
      _servingUnitController.text = draft.defaultServingUnit!;
    }
    if (draft.calories != null) {
      _caloriesController.text = _formatNumber(draft.calories!);
    }
    if (draft.protein != null) {
      _proteinController.text = _formatNumber(draft.protein!);
    }
    if (draft.carbs != null) {
      _carbsController.text = _formatNumber(draft.carbs!);
    }
    if (draft.fat != null) {
      _fatController.text = _formatNumber(draft.fat!);
    }
    _initialized = true;
  }

  String _formatNumber(double value) {
    if (value.truncateToDouble() == value) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  String? _requiredText(String? value, {required String label}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  String? _requiredNumber(String? value, {required String label}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    final parsed = double.tryParse(value.replaceAll(',', '.').trim());
    if (parsed == null || parsed < 0) {
      return '$label must be zero or more.';
    }
    return null;
  }

  String? _optionalNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.replaceAll(',', '.').trim());
    if (parsed == null || parsed <= 0) {
      return 'Must be greater than zero.';
    }
    return null;
  }

  double _parseDouble(String value) =>
      double.parse(value.replaceAll(',', '.').trim());

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final controller = ref.read(barcodeFlowControllerProvider.notifier);
    final servingAmountText = _servingAmountController.text.trim();
    final servingAmount =
        servingAmountText.isEmpty ? null : _parseDouble(servingAmountText);
    final servingUnit = _servingUnitController.text.trim().isEmpty
        ? null
        : _servingUnitController.text.trim();

    try {
      final saved = await controller.saveReviewedFood(
        name: _nameController.text.trim(),
        brand: _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        barcode: widget.barcode,
        defaultServingAmount: servingAmount,
        defaultServingUnit: servingUnit,
        source: _draft?.found == true ? 'openfoodfacts' : 'user',
        calories: _parseDouble(_caloriesController.text),
        protein: _parseDouble(_proteinController.text),
        carbs: _parseDouble(_carbsController.text),
        fat: _parseDouble(_fatController.text),
      );
      if (!mounted) return;
      controller.reset();
      context.go(AppRoutePaths.addFoodDetail(saved.id));
    } on BarcodeConflictException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitError = error.message;
        _isSubmitting = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitError = error.message;
        _isSubmitting = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitError = 'Could not save. $error';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);

    final draft = _draft;
    final isFromOpenFoodFacts = draft?.found == true;
    final hasMissingMacros = draft?.hasMissingMacros == true;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: tokens.sectionSpacing),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review food',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: tokens.sectionSpacing),
            AppStandardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFromOpenFoodFacts
                          ? 'From OpenFoodFacts'
                          : (_initialized
                              ? 'Not found in OpenFoodFacts'
                              : 'New food'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Barcode: ${widget.barcode}',
                        style: theme.textTheme.bodyMedium),
                    if (draft?.sourceUrl != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        draft!.sourceUrl!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      isFromOpenFoodFacts
                          ? 'Review the values below before saving. OpenFoodFacts data can be incomplete or wrong; correct anything that looks off.'
                          : 'No data was returned. Fill the form below and the product will be saved to your local catalog under this barcode.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (hasMissingMacros) ...[
                SizedBox(height: tokens.sectionSpacing),
                const AppErrorBlock(
                  title: 'Missing macros',
                  message:
                      'OpenFoodFacts did not provide all four macros for this product. Fill the empty fields before saving.',
                ),
              ],
              SizedBox(height: tokens.sectionSpacing),
              AppStandardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Identity',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Name',
                      controller: _nameController,
                      validator: (v) => _requiredText(v, label: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Brand (optional)',
                      controller: _brandController,
                    ),
                  ],
                ),
              ),
              SizedBox(height: tokens.sectionSpacing),
              AppStandardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Serving',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'Amount and unit that the macros below refer to. Defaults to 100 g if left blank.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Serving amount',
                            controller: _servingAmountController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: _optionalNumber,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            label: 'Unit',
                            controller: _servingUnitController,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: tokens.sectionSpacing),
              AppStandardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Macros (per serving)',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Calories (kcal)',
                      controller: _caloriesController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) =>
                          _requiredNumber(v, label: 'Calories'),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Protein (g)',
                      controller: _proteinController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) => _requiredNumber(v, label: 'Protein'),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Carbs (g)',
                      controller: _carbsController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) => _requiredNumber(v, label: 'Carbs'),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Fat (g)',
                      controller: _fatController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) => _requiredNumber(v, label: 'Fat'),
                    ),
                  ],
                ),
              ),
              if (_submitError != null) ...[
                SizedBox(height: tokens.sectionSpacing),
                AppErrorBlock(
                  title: 'Could not save',
                  message: _submitError!,
                ),
              ],
              if (_isSubmitting) ...[
                SizedBox(height: tokens.sectionSpacing),
                const AppLoadingBlock(
                  title: 'Saving food',
                  message: 'Adding the product to your local catalog.',
                ),
              ],
              SizedBox(height: tokens.sectionSpacing),
              AppPrimaryButton(
                label: 'Save and add to meal',
                expand: true,
                onPressed: _isSubmitting ? null : _submit,
              ),
              const SizedBox(height: 12),
            AppSecondaryButton(
              label: 'Cancel',
              expand: true,
              onPressed: _isSubmitting
                  ? null
                  : () => context.go(AppRoutePaths.add),
            ),
          ],
        ),
      ),
    );
  }
}
