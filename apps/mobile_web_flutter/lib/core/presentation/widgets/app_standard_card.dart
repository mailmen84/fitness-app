import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AppStandardCard extends StatelessWidget {
  const AppStandardCard({
    required this.child,
    this.padding,
    this.color,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding:
            padding ?? EdgeInsets.all(AppTheme.adaptivePagePadding(context)),
        child: child,
      ),
    );
  }
}
