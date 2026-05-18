import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../today/application/today_dashboard_controller.dart';
import '../../today/domain/today_dashboard.dart';
import '../application/meal_logging_flow_controller.dart';
import '../domain/serving_units.dart';

class MealDetailScreen extends ConsumerStatefulWidget {
  const MealDetailScreen({
    required this.entryId,
    required this.entry,
    super.key,
  });

  final String entryId;
  final TodayMealEntry? entry;

  @override
  ConsumerState<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends ConsumerState<MealDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;
  String? _selectedUnit;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.entry?.quantity.toStringAsFixed(2));
    _notesController = TextEditingController(text: widget.entry?.notes ?? '');
    _selectedUnit = widget.entry?.unit;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
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

  Future<void> _refreshTodayAndReturn() async {
    final flowState = ref.read(mealLoggingFlowControllerProvider);
    await ref.read(todayDashboardControllerProvider.notifier).loadForDate(flowState.selectedDate);
    if (!mounted) {
      return;
    }
    context.go(AppRoutePaths.today);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref.read(mealLoggingFlowControllerProvider.notifier).updateMealEntry(
          entryId: widget.entryId,
          quantity: double.parse(_quantityController.text.trim()),
          unit: _selectedUnit ?? widget.entry?.unit ?? 'serving',
          notes: _notesController.text,
        );
    if (!mounted || !success) {
      return;
    }
    await _refreshTodayAndReturn();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete meal entry?'),
              content: const Text('This removes the item from the selected day and meal section.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!confirmed) {
      return;
    }

    final success = await ref.read(mealLoggingFlowControllerProvider.notifier).deleteMealEntry(widget.entryId);
    if (!mounted || !success) {
      return;
    }
    await _refreshTodayAndReturn();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);
    final flowState = ref.watch(mealLoggingFlowControllerProvider);
    final isSubmitting = flowState.submission is AsyncLoading<void>;

    if (widget.entry == null) {
      return AppErrorBlock(
        title: 'Meal entry unavailable',
        message: 'Open meal detail from the Today dashboard to edit or delete an entry.',
        action: AppPrimaryButton(
          label: 'Back to today',
          expand: true,
          onPressed: () => context.go(AppRoutePaths.today),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: tokens.sectionSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSecondaryButton(
            label: 'Back to today',
            onPressed: () => context.go(AppRoutePaths.today),
          ),
          SizedBox(height: tokens.sectionSpacing),
          AppStandardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.entry!.foodName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Editing ${flowState.mealSection.title.toLowerCase()} on the selected day.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '${widget.entry!.calories.toStringAsFixed(0)} kcal | P ${widget.entry!.protein.toStringAsFixed(0)}g | C ${widget.entry!.carbs.toStringAsFixed(0)}g | F ${widget.entry!.fat.toStringAsFixed(0)}g',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.sectionSpacing),
          AppStandardCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label: 'Amount',
                    controller: _quantityController,
                    validator: _validateQuantity,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final current = _selectedUnit ?? widget.entry!.unit;
                      final options = ServingUnits.optionsFor(current);
                      if (!options.contains(widget.entry!.unit)) {
                        options.add(widget.entry!.unit);
                      }
                      return DropdownButtonFormField<String>(
                        value: current,
                        items: [
                          for (final unit in options)
                            DropdownMenuItem<String>(
                              value: unit,
                              child: Text(ServingUnits.label(unit)),
                            ),
                        ],
                        decoration: const InputDecoration(labelText: 'Unit'),
                        onChanged: (value) =>
                            setState(() => _selectedUnit = value),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Notes',
                    controller: _notesController,
                    hintText: 'Optional note for this entry',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  AppPrimaryButton(
                    label: 'Save changes',
                    expand: true,
                    onPressed: isSubmitting ? null : _save,
                  ),
                  const SizedBox(height: 12),
                  AppSecondaryButton(
                    label: 'Delete entry',
                    expand: true,
                    onPressed: isSubmitting ? null : _delete,
                  ),
                ],
              ),
            ),
          ),
          if (isSubmitting) ...[
            SizedBox(height: tokens.sectionSpacing),
            const AppLoadingBlock(
              title: 'Updating meal entry',
              message: 'Saving changes and refreshing Today for the selected day.',
            ),
          ],
          if (flowState.submission case AsyncError<void>(:final error)) ...[
            SizedBox(height: tokens.sectionSpacing),
            AppErrorBlock(
              title: 'Meal entry update failed',
              message: _errorMessage(error),
            ),
          ],
        ],
      ),
    );
  }
}


