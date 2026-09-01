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
/// [accentColor] tints the field so debit/credit are distinguishable at a
/// glance.
class AmountField extends StatefulWidget {
  const AmountField({
    super.key,
    required this.label,
    required this.controller,
    this.suffixText,
    this.enabled = true,
    this.accentColor,
    this.icon = Icons.payments_rounded,
  });

  final String label;
  final TextEditingController controller;
  final String? suffixText;
  final bool enabled;
  final Color? accentColor;
  final IconData icon;

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  late final FocusNode _focusNode = FocusNode()..addListener(_onFocusChange);
  bool _focused = false;

  void _onFocusChange() {
    if (_focusNode.hasFocus != _focused) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.accentColor ?? theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, left: 4, bottom: 7),
          child: Text(
            widget.label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: _focused ? accent : theme.colorScheme.onSurfaceVariant,
              fontSize: 13.5,
            ),
          ),
        ),
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.start,
          textDirection: TextDirection.ltr,
          inputFormatters: [_DecimalInputFormatter()],
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: accent,
          ),
          decoration: InputDecoration(
            hintText: '0',
            suffixText: widget.suffixText,
            suffixStyle: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(right: 12, left: 12),
              child: Icon(widget.icon, size: 20, color: accent),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: accent, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}
