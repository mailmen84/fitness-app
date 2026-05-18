import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../application/meal_logging_flow_controller.dart';
import 'widgets/meal_logging_target_card.dart';

class AddScreen extends ConsumerWidget {
  const AddScreen({super.key});

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
            title: 'Meal logging hub',
            description:
                'Choose the day and meal section first, then continue into food search or the quicker guided flow.',
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
                  'Choose a flow',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Search the seeded demo food set, review nutrition details, and add the item into the selected meal.',
                  style: theme.textTheme.bodyMedium,
                ),
                SizedBox(height: tokens.sectionSpacing),
                AppPrimaryButton(
                  label: 'Search foods',
                  expand: true,
                  onPressed: () => context.go(AppRoutePaths.addSearch),
                ),
                const SizedBox(height: 12),
                AppSecondaryButton(
                  label: 'Scan barcode',
                  expand: true,
                  onPressed: () => context.go(AppRoutePaths.addScan),
                ),
                const SizedBox(height: 12),
                AppSecondaryButton(
                  label: 'Quick add setup',
                  expand: true,
                  onPressed: () => context.go(AppRoutePaths.addQuick),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.sectionSpacing),
          const AppEmptyStateBlock(
            title: 'More add shortcuts come later',
            message:
                'Recipes and other shortcuts stay out of scope for now. Use food search, the barcode scanner, or quick add setup for the stable MVP path.',
          ),
        ],
      ),
    );
  }
}

