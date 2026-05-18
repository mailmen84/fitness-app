import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/add/presentation/add_screen.dart';
import '../../features/add/presentation/barcode_review_screen.dart';
import '../../features/add/presentation/barcode_scanner_screen.dart';
import '../../features/add/presentation/custom_food_screen.dart';
import '../../features/add/presentation/food_detail_screen.dart';
import '../../features/add/presentation/food_search_screen.dart';
import '../../features/add/presentation/meal_detail_screen.dart';
import '../../features/add/presentation/quick_add_screen.dart';
import '../../features/app_shell/presentation/app_shell_page.dart';
import '../../features/auth/application/auth_session.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/password_reset_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/more/presentation/diet_setup_screen.dart';
import '../../features/more/presentation/goal_settings_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/more/presentation/preferences_screen.dart';
import '../../features/more/presentation/profile_settings_screen.dart';
import '../../features/more/presentation/support_placeholder_screen.dart';
import '../../features/nutrition/presentation/nutrition_screen.dart';
import '../../features/onboarding/presentation/onboarding_activity_screen.dart';
import '../../features/onboarding/presentation/onboarding_goal_screen.dart';
import '../../features/onboarding/presentation/onboarding_stats_screen.dart';
import '../../features/onboarding/presentation/onboarding_target_screen.dart';
import '../../features/ped/presentation/ped_placeholder_screen.dart';
import '../../features/progress/presentation/add_measurement_screen.dart';
import '../../features/progress/presentation/add_weight_screen.dart';
import '../../features/progress/presentation/measurement_log_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/progress/presentation/weight_log_screen.dart';
import '../../features/today/domain/today_dashboard.dart';
import '../../features/today/presentation/today_screen.dart';
import 'app_route_paths.dart';

const _authLocations = <String>{
  AppRoutePaths.login,
  AppRoutePaths.signup,
  AppRoutePaths.forgotPassword,
};

const _onboardingLocations = <String>{
  AppRoutePaths.onboardingGoal,
  AppRoutePaths.onboardingStats,
  AppRoutePaths.onboardingActivity,
  AppRoutePaths.onboardingTarget,
};

const _protectedPrefixes = <String>[
  AppRoutePaths.today,
  AppRoutePaths.nutrition,
  AppRoutePaths.add,
  AppRoutePaths.progress,
  AppRoutePaths.more,
];

bool _matchesPrefix(String location, String prefix) {
  return location == prefix || location.startsWith('$prefix/');
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authSession = ref.watch(authSessionProvider);

  return GoRouter(
    initialLocation: AppRoutePaths.welcome,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthLocation = _authLocations.contains(location);
      final isOnboardingLocation = _onboardingLocations.contains(location);
      final isProtectedLocation = _protectedPrefixes.any(
        (prefix) => _matchesPrefix(location, prefix),
      );
      final isWelcomeLocation = location == AppRoutePaths.welcome;

      if (authSession.isHydrating) {
        if (isProtectedLocation || isOnboardingLocation) {
          return AppRoutePaths.welcome;
        }
        return null;
      }

      final isAuthenticated = authSession.isAuthenticated;
      final hasCompletedOnboarding = authSession.hasCompletedOnboarding;

      if (!isAuthenticated && isProtectedLocation) {
        return AppRoutePaths.login;
      }
      if (!isAuthenticated && isOnboardingLocation) {
        return AppRoutePaths.signup;
      }
      if (isAuthenticated && !hasCompletedOnboarding) {
        if (isWelcomeLocation || isProtectedLocation || isAuthLocation) {
          return AppRoutePaths.onboardingGoal;
        }
      }
      if (isAuthenticated && hasCompletedOnboarding) {
        if (isWelcomeLocation || isAuthLocation || isOnboardingLocation) {
          return AppRoutePaths.today;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutePaths.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.forgotPassword,
        builder: (context, state) => const PasswordResetScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.onboardingGoal,
        builder: (context, state) => const OnboardingGoalScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.onboardingStats,
        builder: (context, state) => const OnboardingStatsScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.onboardingActivity,
        builder: (context, state) => const OnboardingActivityScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.onboardingTarget,
        builder: (context, state) => const OnboardingTargetScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShellPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.today,
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.nutrition,
                builder: (context, state) => const NutritionScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.add,
                builder: (context, state) => const AddScreen(),
                routes: [
                  GoRoute(
                    path: 'quick',
                    builder: (context, state) => const QuickAddScreen(),
                  ),
                  GoRoute(
                    path: 'search',
                    builder: (context, state) => const FoodSearchScreen(),
                  ),
                  GoRoute(
                    path: 'scan',
                    builder: (context, state) => const BarcodeScannerScreen(),
                    routes: [
                      GoRoute(
                        path: 'review/:barcode',
                        builder: (context, state) => BarcodeReviewScreen(
                          barcode: state.pathParameters['barcode']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'custom',
                    builder: (context, state) => const CustomFoodScreen(),
                  ),
                  GoRoute(
                    path: 'food/:foodId',
                    builder: (context, state) => FoodDetailScreen(
                      foodId: state.pathParameters['foodId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'meal/:entryId',
                    builder: (context, state) => MealDetailScreen(
                      entryId: state.pathParameters['entryId']!,
                      entry: state.extra is TodayMealEntry
                          ? state.extra! as TodayMealEntry
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.progress,
                builder: (context, state) => const ProgressScreen(),
                routes: [
                  GoRoute(
                    path: 'weight',
                    builder: (context, state) => const WeightLogScreen(),
                    routes: [
                      GoRoute(
                        path: 'add',
                        builder: (context, state) => const AddWeightScreen(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'measurements',
                    builder: (context, state) => const MeasurementLogScreen(),
                    routes: [
                      GoRoute(
                        path: 'add',
                        builder: (context, state) => const AddMeasurementScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.more,
                builder: (context, state) => const MoreScreen(),
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (context, state) => const ProfileSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'goals',
                    builder: (context, state) => const GoalSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'preferences',
                    builder: (context, state) => const PreferencesScreen(),
                  ),
                  GoRoute(
                    path: 'diet-setup',
                    builder: (context, state) => const DietSetupScreen(),
                  ),
                  GoRoute(
                    path: 'support',
                    builder: (context, state) => const SupportPlaceholderScreen(),
                  ),
                  GoRoute(
                    path: 'ped',
                    builder: (context, state) => const PedPlaceholderScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
