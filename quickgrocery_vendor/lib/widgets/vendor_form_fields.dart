import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared text field with guaranteed readable input, hint, label, and errors.
class VendorTextFormField extends StatelessWidget {
  const VendorTextFormField({
    super.key,
    this.controller,
    this.initialValue,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.autovalidateMode,
    this.isDense = false,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final AutovalidateMode? autovalidateMode;
  final bool isDense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      inputFormatters: inputFormatters,
      autovalidateMode: autovalidateMode,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: enabled ? textColor : textColor.withValues(alpha: 0.5),
        height: maxLines > 1 ? 1.4 : null,
      ),
      cursorColor: theme.colorScheme.primary,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        isDense: isDense,
      ),
    );
  }
}

/// Dropdown with the same contrast rules as [VendorTextFormField].
class VendorDropdownFormField<T> extends StatelessWidget {
  const VendorDropdownFormField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hint,
    this.prefixIcon,
    this.validator,
    this.enabled = true,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final String? Function(T?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down, color: textColor),
      dropdownColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
    );
  }
}
