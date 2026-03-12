import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';

class PedPlaceholderScreen extends StatelessWidget {
  const PedPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: tokens.sectionSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppStandardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PED module planned later',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This route stays visible so the future module has a defined home, but it remains fully inactive in the MVP.',
                  style: theme.textTheme.bodyLarge,
                ),
                SizedBox(height: tokens.sectionSpacing),
                AppSecondaryButton(
                  label: 'Back to more',
                  onPressed: () => context.go(AppRoutePaths.more),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.sectionSpacing),
          const AppEmptyStateBlock(
            title: 'Inactive by design',
            message:
                'No tracking logic, calculations, workflows, or recommendations are implemented here. This module is intentionally reserved for later scope definition.',
            icon: Icons.lock_clock_rounded,
          ),
          SizedBox(height: tokens.sectionSpacing),
          AppStandardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What is intentionally not included',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                const _PedRuleRow(text: 'No PED tracking or cycle logging'),
                const Divider(height: 24),
                const _PedRuleRow(text: 'No calculations or estimations'),
                const Divider(height: 24),
                const _PedRuleRow(text: 'No guidance or recommendations'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PedRuleRow extends StatelessWidget {
  const _PedRuleRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.block_rounded, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}