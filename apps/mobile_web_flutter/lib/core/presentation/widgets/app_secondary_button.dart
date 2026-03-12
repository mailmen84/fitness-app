import 'package:flutter/material.dart';

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    Widget button;

    if (icon == null) {
      button = OutlinedButton(
        onPressed: onPressed,
        child: Text(label),
      );
    } else {
      button = OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }

    if (!expand) {
      return button;
    }

    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }
}