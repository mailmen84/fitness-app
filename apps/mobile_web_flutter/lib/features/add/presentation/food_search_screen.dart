import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../application/food_search_controller.dart';
import '../application/meal_logging_flow_controller.dart';
import '../domain/meal_logging_models.dart';
import 'widgets/meal_logging_target_card.dart';

class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  String _errorMessage(Object error) {
    final message = error.toString().trim();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);
    final flowState = ref.watch(mealLoggingFlowControllerProvider);
    final flowController = ref.read(mealLoggingFlowControllerProvider.notifier);
    final searchState = ref.watch(foodSearchControllerProvider);
    final searchController = ref.read(foodSearchControllerProvider.notifier);

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: tokens.sectionSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MealLoggingTargetCard(
            title: 'Food search',
            description:
                'Search the seeded demo food set and open a food to choose quantity before saving it into the selected meal.',
            selectedDate: flowState.selectedDate,
            selectedMealSection: flowState.mealSection,
            onPickDate: _pickDate,
            onMealSectionSelected: flowController.setMealSection,
          ),
          SizedBox(height: tokens.sectionSpacing),
          AppSecondaryButton(
            label: 'Back to add hub',
            onPressed: () => context.go(AppRoutePaths.add),
          ),
          SizedBox(height: tokens.sectionSpacing),
          AppStandardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search foods',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Food name',
                  controller: _searchController,
                  hintText: 'Try Greek yogurt, rice, salmon, banana...',
                  textInputAction: TextInputAction.search,
                  onFieldSubmitted: searchController.search,
                ),
                const SizedBox(height: 12),
                AppPrimaryButton(
                  label: 'Search',
                  expand: true,
                  onPressed: () => searchController.search(_searchController.text),
                ),
                const SizedBox(height: 12),
                AppSecondaryButton(
                  label: 'Scan barcode instead',
                  expand: true,
                  onPressed: () => context.go(AppRoutePaths.addScan),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.sectionSpacing),
          searchState.results.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => const AppLoadingBlock(
              title: 'Searching foods',
              message:
                  'Looking through the seeded demo dataset for matching foods.',
            ),
            error: (error, _) => AppErrorBlock(
              title: 'Food search failed',
              message: _errorMessage(error),
              action: AppPrimaryButton(
                label: 'Retry search',
                expand: true,
                onPressed: searchController.retry,
              ),
            ),
            data: (value) => !searchState.hasQuery
                ? const AppEmptyStateBlock(
                    title: 'Start with a search term',
                    message:
                        'Search by a food name to open its detail screen and add it to the selected meal.',
                  )
                : value.isEmpty
                    ? AppEmptyStateBlock(
                        title: 'No matching foods found',
                        message:
                            'Try a broader search term from the seeded demo dataset, or scan a barcode to fetch product data from Open Food Facts.',
                        action: AppPrimaryButton(
                          label: 'Scan barcode',
                          expand: true,
                          onPressed: () => context.go(AppRoutePaths.addScan),
                        ),
                      )
                    : Column(
                        children: [
                          for (var index = 0; index < value.length; index++) ...[
                            _FoodSearchResultCard(food: value[index]),
                            if (index < value.length - 1)
                              SizedBox(height: tokens.sectionSpacing),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _FoodSearchResultCard extends StatelessWidget {
  const _FoodSearchResultCard({required this.food});

  final FoodSearchResult food;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppStandardCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.go(AppRoutePaths.addFoodDetail(food.id)),
        child: Padding(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (food.brand != null && food.brand!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            food.brand!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: colorScheme.primary),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Serving: ${food.servingLabel}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${food.calories.toStringAsFixed(0)} kcal | P ${food.protein.toStringAsFixed(0)}g | C ${food.carbs.toStringAsFixed(0)}g | F ${food.fat.toStringAsFixed(0)}g',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


