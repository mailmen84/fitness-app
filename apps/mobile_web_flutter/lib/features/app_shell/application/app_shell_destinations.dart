import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_route_paths.dart';

@immutable
class AppShellDestination {
  const AppShellDestination({
    required this.label,
    required this.icon,
    required this.location,
  });

  final String label;
  final IconData icon;
  final String location;
}

final appShellDestinationsProvider = Provider<List<AppShellDestination>>((ref) {
  return const [
    AppShellDestination(
      label: 'Today',
      icon: Icons.today_rounded,
      location: AppRoutePaths.today,
    ),
    AppShellDestination(
      label: 'Nutrition',
      icon: Icons.restaurant_menu_rounded,
      location: AppRoutePaths.nutrition,
    ),
    AppShellDestination(
      label: 'Add',
      icon: Icons.add_circle_outline_rounded,
      location: AppRoutePaths.add,
    ),
    AppShellDestination(
      label: 'Progress',
      icon: Icons.show_chart_rounded,
      location: AppRoutePaths.progress,
    ),
    AppShellDestination(
      label: 'More',
      icon: Icons.menu_rounded,
      location: AppRoutePaths.more,
    ),
  ];
});