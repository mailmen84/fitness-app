import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../today/application/today_dashboard_controller.dart';
import '../application/food_search_controller.dart';
import '../application/meal_logging_flow_controller.dart';
import '../domain/meal_logging_models.dart';
import 'widgets/meal_logging_target_card.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  const FoodDetailScreen({
    required this.foodId,
    super.key,
  });

  final String foodId;

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;
  String? _selectedUnit;
  bool _initializedForm = false;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final controller = ref.read(mealLoggingFlowControllerProvider.notifier);
    final state = ref.read(mealLoggingFlowControllerProvider);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: state.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      controller.setSelectedDate(pickedDate);
    }
  }

  String? _validateQuantity(String? value) {
    final quantity = double.tryParse(value?.trim() ?? '');
    if (quantity == null || quantity <= 0) {
      return 'Enter a valid amount greater than zero.';
    }
    return null;
  }

  String _errorMessage(Object error) {
    final message = error.toString().trim();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }

  Future<void> _save(FoodDetail food) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final quantity = double.parse(_quantityController.text.trim());
    final success = await ref
        .read(mealLoggingFlowControllerProvider.notifier)
        .createMealEntry(
          foodId: food.id,
          quantity: quantity,
          unit: _selectedUnit ?? food.defaultServingUnit,
          notes: _notesController.text,
        );
    if (!mounted || !success) {
      return;
    }

    final flowState = ref.read(mealLoggingFlowControllerProvider);
    await ref
        .read(todayDashboardControllerProvider.notifier)
        .loadForDate(flowState.selectedDate);
    if (!mounted) {
      return;
    }
    context.go(AppRoutePaths.today);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);
    final flowState = ref.watch(mealLoggingFlowControllerProvider);
    final flowController = ref.read(mealLoggingFlowControllerProvider.notifier);
    final foodDetail = ref.watch(foodDetailProvider(widget.foodId));
    final isSubmitting = flowState.submission is AsyncLoading<void>;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: tokens.sectionSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MealLoggingTargetCard(
            title: 'Food detail',
            description:
                'Review the serving information, set the amount you want, and save it into the selected meal.',
            selectedDate: flowState.selectedDate,
            selectedMealSection: flowState.mealSection,
            onPickDate: _pickDate,
            onMealSectionSelected: flowController.setMealSection,
          ),
          SizedBox(height: tokens.sectionSpacing),
          AppSecondaryButton(
            label: 'Back to search',
            onPressed: () => context.go(AppRoutePaths.addSearch),
          ),
          SizedBox(height: tokens.sectionSpacing),
          foodDetail.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => const AppLoadingBlock(
              title: 'Loading food detail',
              message:
                  'Pulling serving details and nutrient values for this food.',
            ),
            error: (error, _) => AppErrorBlock(
              title: 'Could not load this food',
              message: _errorMessage(error),
              action: AppPrimaryButton(
                label: 'Back to search',
                expand: true,
                onPressed: () => context.go(AppRoutePaths.addSearch),
              ),
            ),
            data: (value) => _FoodDetailContent(
              food: value,
              formKey: _formKey,
              quantityController: _quantityController,
              notesController: _notesController,
              selectedUnit: _selectedUnit,
              onUnitChanged: (value) => setState(() => _selectedUnit = value),
              validateQuantity: _validateQuantity,
              onSave: () => _save(value),
              isSubmitting: isSubmitting,
              initializedForm: _initializedForm,
              onInitializeForm: () {
                if (_initializedForm) {
                  return;
                }
                _initializedForm = true;
                _quantityController.text = value.defaultServingAmount
                            .truncateToDouble() ==
                        value.defaultServingAmount
                    ? value.defaultServingAmount.toStringAsFixed(0)
                    : value.defaultServingAmount.toStringAsFixed(2);
                _selectedUnit = value.defaultServingUnit;
              },
            ),
          ),
          if (isSubmitting) ...[
            SizedBox(height: tokens.sectionSpacing),
            const AppLoadingBlock(
              title: 'Saving meal entry',
              message:
                  'Adding the selected food into the chosen meal and refreshing Today.',
            ),
          ],
          if (flowState.submission case AsyncError<void>(:final error)) ...[
            SizedBox(height: tokens.sectionSpacing),
            AppErrorBlock(
              title: 'Could not save meal entry',
              message: _errorMessage(error),
            ),
          ],
        ],
      ),
    );
  }
}

class _FoodDetailContent extends StatelessWidget {
  const _FoodDetailContent({
    required this.food,
    required this.formKey,
    required this.quantityController,
    required this.notesController,
    required this.selectedUnit,
    required this.onUnitChanged,
    required this.validateQuantity,
    required this.onSave,
    required this.isSubmitting,
    required this.initializedForm,
    required this.onInitializeForm,
  });

  final FoodDetail food;
  final GlobalKey<FormState> formKey;
  final TextEditingController quantityController;
  final TextEditingController notesController;
  final String? selectedUnit;
  final ValueChanged<String?> onUnitChanged;
  final String? Function(String?) validateQuantity;
  final VoidCallback onSave;
  final bool isSubmitting;
  final bool initializedForm;
  final VoidCallback onInitializeForm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);

    if (!initializedForm) {
      onInitializeForm();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppStandardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                food.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (food.brand != null && food.brand!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(food.brand!, style: theme.textTheme.bodyLarge),
              ],
              const SizedBox(height: 12),
              Text(
                'Default serving: ${food.servingLabel}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${food.calories.toStringAsFixed(0)} kcal | P ${food.protein.toStringAsFixed(0)}g | C ${food.carbs.toStringAsFixed(0)}g | F ${food.fat.toStringAsFixed(0)}g',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppStandardCard(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Serving to add',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Amount',
                  controller: quantityController,
                  validator: validateQuantity,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedUnit ?? food.defaultServingUnit,
                  items: [
                    DropdownMenuItem<String>(
                      value: food.defaultServingUnit,
                      child: Text(food.defaultServingUnit),
                    ),
                  ],
                  decoration: const InputDecoration(labelText: 'Unit'),
                  onChanged: onUnitChanged,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Notes',
                  controller: notesController,
                  hintText: 'Optional note for this meal entry',
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                AppPrimaryButton(
                  label: 'Add to meal',
                  expand: true,
                  onPressed: isSubmitting ? null : onSave,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppStandardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nutrients',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              for (var index = 0; index < food.nutrients.length; index++) ...[
                Row(
                  children: [
                    Expanded(child: Text(food.nutrients[index].name)),
                    Text(
                      '${food.nutrients[index].amount.toStringAsFixed(1)} ${food.nutrients[index].unit}',
                    ),
                  ],
                ),
                if (index < food.nutrients.length - 1)
                  const Divider(height: 24),
              ],
            ],
          ),
        ),
      ],
    );
  }
}