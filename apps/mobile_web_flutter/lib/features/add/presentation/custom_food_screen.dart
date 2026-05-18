import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/app_api_client.dart';
import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/serving_units.dart';
import '../infrastructure/barcode_repository.dart';

/// Manual food creation screen. Used when the user has neither a barcode nor a
/// matching seeded food. On save, creates a `source = 'user'` food and routes
/// directly to its food detail screen so it can be added to a meal right away.
class CustomFoodScreen extends ConsumerStatefulWidget {
  const CustomFoodScreen({super.key});

  @override
  ConsumerState<CustomFoodScreen> createState() => _CustomFoodScreenState();
}

class _CustomFoodScreenState extends ConsumerState<CustomFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _servingAmountController = TextEditingController(text: '100');
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  String _servingUnit = ServingUnits.defaultUnit;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _servingAmountController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
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

  String? _servingAmountValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.replaceAll(',', '.').trim());
    if (parsed == null || parsed <= 0) {
      return 'Serving amount must be greater than zero.';
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

    final repository = ref.read(barcodeRepositoryProvider);
    final servingAmountText = _servingAmountController.text.trim();
    final servingAmount =
        servingAmountText.isEmpty ? null : _parseDouble(servingAmountText);

    try {
      final saved = await repository.createFood(
        name: _nameController.text.trim(),
        brand: _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        defaultServingAmount: servingAmount,
        defaultServingUnit: _servingUnit,
        source: 'user',
        calories: _parseDouble(_caloriesController.text),
        protein: _parseDouble(_proteinController.text),
        carbs: _parseDouble(_carbsController.text),
        fat: _parseDouble(_fatController.text),
      );
      if (!mounted) return;
      context.go(AppRoutePaths.addFoodDetail(saved.id));
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

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: tokens.sectionSpacing),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a custom food',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a food when you cannot find it in search and there is no barcode to scan. It is saved to your local catalog and can be reused later.',
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: tokens.sectionSpacing),
            AppStandardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Identity',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
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
                  Text(
                    'Serving',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
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
                            decimal: true,
                          ),
                          validator: _servingAmountValidator,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _servingUnit,
                          items: [
                            for (final unit
                                in ServingUnits.optionsFor(_servingUnit))
                              DropdownMenuItem<String>(
                                value: unit,
                                child: Text(ServingUnits.label(unit)),
                              ),
                          ],
                          decoration: const InputDecoration(labelText: 'Unit'),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _servingUnit = value);
                          },
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
                  Text(
                    'Macros (per serving)',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Calories (kcal)',
                    controller: _caloriesController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => _requiredNumber(v, label: 'Calories'),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Protein (g)',
                    controller: _proteinController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => _requiredNumber(v, label: 'Protein'),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Carbs (g)',
                    controller: _carbsController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => _requiredNumber(v, label: 'Carbs'),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Fat (g)',
                    controller: _fatController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
                message: 'Adding the food to your local catalog.',
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
