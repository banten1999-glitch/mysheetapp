import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Rejects any edit that would make the field not match a plain decimal
/// number (at most 2 fraction digits), instead of filtering per character.
class _DecimalInputFormatter extends TextInputFormatter {
  static final RegExp _pattern = RegExp(r'^\d*\.?\d{0,2}$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty || _pattern.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}

/// Numeric-only amount input; supports decimals, rejects text and negatives.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.label,
    required this.controller,
    this.suffixText,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final String? suffixText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.start,
      inputFormatters: [_DecimalInputFormatter()],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffixText,
        prefixIcon: const Icon(Icons.payments_outlined),
      ),
    );
  }
}
