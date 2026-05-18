/// Canonical list of serving units the client knows how to display.
///
/// The backend stores units as free-form strings, so this list is purely a
/// client-side UX helper: it gives users a clean dropdown of common choices
/// while still allowing custom units (anything coming back from the server
/// that is not in this list is appended automatically so the value never gets
/// dropped).
class ServingUnits {
  const ServingUnits._();

  /// Default unit when nothing is known.
  static const String defaultUnit = 'g';

  /// Common unit codes shown in dropdowns.
  static const List<String> common = <String>[
    'g',
    'ml',
    'szt',
    'oz',
  ];

  /// Human-readable label for a unit code.
  static String label(String unit) {
    switch (unit) {
      case 'g':
        return 'g (grams)';
      case 'ml':
        return 'ml (milliliters)';
      case 'szt':
        return 'szt (pieces)';
      case 'oz':
        return 'oz (ounces)';
      default:
        return unit;
    }
  }

  /// Builds the list of unit codes the dropdown should show. Always contains
  /// every entry in [common]; if [selected] is non-empty and not part of the
  /// common list, it is appended so the dropdown can render its current value.
  static List<String> optionsFor(String? selected) {
    final options = List<String>.of(common);
    final value = selected?.trim();
    if (value != null && value.isNotEmpty && !options.contains(value)) {
      options.add(value);
    }
    return options;
  }
}
