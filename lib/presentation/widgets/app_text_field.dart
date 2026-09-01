import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Labelled input used across the app. The label sits above the field
/// (clearer in RTL than a floating label) and the leading icon tints on
/// focus, giving obvious focus feedback.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.suffixText,
    this.enabled = true,
    this.errorText,
    this.onChanged,
    this.textDirection,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final int minLines;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? suffixText;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextDirection? textDirection;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
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
    final accent = _focused
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, left: 4, bottom: 7),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 160),
            style: theme.textTheme.labelLarge!.copyWith(
              color: accent,
              fontSize: 13.5,
            ),
            child: Text(widget.label),
          ),
        ),
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          textDirection: widget.textDirection,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            suffixText: widget.suffixText,
            suffixStyle: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: widget.icon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 12, left: 12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      child: Icon(widget.icon, size: 20, color: accent),
                    ),
                  ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44),
          ),
        ),
      ],
    );
  }
}

/// Read-only field that opens something on tap (date picker, etc).
class AppTapField extends StatelessWidget {
  const AppTapField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.icon,
    this.trailing,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, left: 4, bottom: 7),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13.5,
            ),
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: icon == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(right: 12, left: 12),
                      child: Icon(
                        icon,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
              prefixIconConstraints: const BoxConstraints(minWidth: 44),
            ),
            child: Row(
              children: [
                Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
                ?trailing,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
