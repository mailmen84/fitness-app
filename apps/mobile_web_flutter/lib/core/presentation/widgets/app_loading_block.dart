import 'package:flutter/material.dart';

import 'app_standard_card.dart';

class AppLoadingBlock extends StatelessWidget {
  const AppLoadingBlock({
    this.title = 'Loading placeholder',
    this.message = 'This area is reserved for real content and data in a later prompt.',
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppStandardCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}