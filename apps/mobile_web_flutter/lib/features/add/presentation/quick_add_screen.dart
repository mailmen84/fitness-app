import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../application/meal_logging_flow_controller.dart';
import 'widgets/meal_logging_target_card.dart';

class QuickAddScreen extends ConsumerWidget {
  const QuickAddScreen({super.key});

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);
    final state = ref.watch(mealLoggingFlowControllerProvider);
    final controller = ref.read(mealLoggingFlowControllerProvider.notifier);

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: tokens.sectionSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MealLoggingTargetCard(
            title: 'Quick add setup',
            description:
                'This guided screen is meant for fast entry from Today. Confirm the date and target meal before searching the food dataset.',
            selectedDate: state.selectedDate,
            selectedMealSection: state.mealSection,
            onPickDate: () => _pickDate(context, ref),
            onMealSectionSelected: controller.setMealSection,
          ),
          SizedBox(height: tokens.sectionSpacing),
          AppStandardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected target',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Food items added next will land in ${state.mealSection.title.toLowerCase()} for the chosen day.',
                  style: theme.textTheme.bodyMedium,
                ),
                SizedBox(height: tokens.sectionSpacing),
                AppPrimaryButton(
                  label: 'Continue to search',
                  expand: true,
                  onPressed: () => context.go(AppRoutePaths.addSearch),
                ),
                const SizedBox(height: 12),
                AppSecondaryButton(
                  label: 'Back to add hub',
                  expand: true,
                  onPressed: () => context.go(AppRoutePaths.add),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
