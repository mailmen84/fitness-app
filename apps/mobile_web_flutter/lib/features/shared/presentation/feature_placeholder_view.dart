import 'package:flutter/material.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/theme/app_theme.dart';

class FeaturePlaceholderView extends StatelessWidget {
  const FeaturePlaceholderView({
    required this.title,
    required this.description,
    this.eyebrow,
    this.actions = const <Widget>[],
    this.sections = const <Widget>[],
    this.footer,
    super.key,
  });

  final String title;
  final String description;
  final String? eyebrow;
  final List<Widget> actions;
  final List<Widget> sections;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppStandardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: tokens.sectionSpacing / 2),
                ],
                Text(
                  title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: theme.textTheme.bodyLarge,
                ),
                if (actions.isNotEmpty) ...[
                  SizedBox(height: tokens.sectionSpacing),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
          for (final section in sections)
            Padding(
              padding: EdgeInsets.only(top: tokens.sectionSpacing),
              child: section,
            ),
          if (footer != null)
            Padding(
              padding: EdgeInsets.only(top: tokens.sectionSpacing),
              child: footer!,
            ),
        ],
      ),
    );
  }
}