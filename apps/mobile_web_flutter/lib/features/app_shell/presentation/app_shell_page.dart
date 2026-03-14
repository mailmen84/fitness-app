import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/environment.dart';
import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../application/app_shell_destinations.dart';

class AppShellPage extends ConsumerWidget {
  const AppShellPage({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinations = ref.watch(appShellDestinationsProvider);
    final currentDestination = destinations[navigationShell.currentIndex];
    final isCompactWidth = AppTheme.isCompactWidth(context);
    final width = MediaQuery.sizeOf(context).width;

    return AppScaffold(
      appBar: AppTopAppBar(
        title: isCompactWidth
            ? currentDestination.label
            : '${Environment.appName} - ${currentDestination.label}',
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        labelBehavior: width < 420
            ? NavigationDestinationLabelBehavior.onlyShowSelected
            : NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              label: destination.label,
            ),
        ],
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
      body: navigationShell,
    );
  }
}
