import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/view/cart/domain/cart_models.dart';

class DeliveryInstructionsField extends StatefulWidget {
  const DeliveryInstructionsField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final DeliveryInstructions value;
  final ValueChanged<DeliveryInstructions> onChanged;

  @override
  State<DeliveryInstructionsField> createState() =>
      _DeliveryInstructionsFieldState();
}

class _DeliveryInstructionsFieldState extends State<DeliveryInstructionsField> {
  late final TextEditingController _gateCode;
  late final TextEditingController _landmark;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _gateCode = TextEditingController(text: widget.value.gateCode);
    _landmark = TextEditingController(text: widget.value.landmark);
    _notes = TextEditingController(text: widget.value.notes);
  }

  @override
  void dispose() {
    _gateCode.dispose();
    _landmark.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      widget.value.copyWith(
        gateCode: _gateCode.text.trim(),
        landmark: _landmark.text.trim(),
        notes: _notes.text.trim(),
      ),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: AppSurface.textMuted,
          fontSize: 13,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: const BorderSide(color: AppSurface.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: const BorderSide(color: AppSurface.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.notes_rounded, size: 18, color: AppSurface.text),
            const SizedBox(width: 8),
            Text(
              'Delivery instructions',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppSurface.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _gateCode,
          onChanged: (_) => _emit(),
          style: GoogleFonts.poppins(fontSize: 13.5, color: AppSurface.text),
          decoration: _decoration('Gate code'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _landmark,
          onChanged: (_) => _emit(),
          style: GoogleFonts.poppins(fontSize: 13.5, color: AppSurface.text),
          decoration: _decoration('Landmark'),
        ),
        const SizedBox(height: 4),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: widget.value.leaveAtDoor,
          activeTrackColor: AppColor.primary.withValues(alpha: 0.35),
          thumbColor: WidgetStateProperty.all(AppColor.primary),
          title: Text(
            'Leave at door',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: AppSurface.text,
            ),
          ),
          onChanged: (v) => widget.onChanged(
            widget.value.copyWith(leaveAtDoor: v),
          ),
        ),
        TextField(
          controller: _notes,
          onChanged: (_) => _emit(),
          maxLines: 2,
          style: GoogleFonts.poppins(fontSize: 13.5, color: AppSurface.text),
          decoration: _decoration('Notes (ring bell, call on arrival…)'),
        ),
      ],
    );
  }
}
