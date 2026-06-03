import 'package:flutter/material.dart';

/// Copy-friendly label for order IDs, names, phones, emails, and addresses.
class AdminSelectableText extends StatelessWidget {
  const AdminSelectableText(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.textAlign,
  });

  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      data,
      style: style,
      maxLines: maxLines,
      textAlign: textAlign,
    );
  }
}
