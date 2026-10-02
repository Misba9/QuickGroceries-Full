import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/view/delivery_tips/models/delivery_tip_settings.dart';

/// Checkout tip selector — optional, single selection, yellow heart theme.
class CheckoutTipSection extends StatefulWidget {
  const CheckoutTipSection({
    super.key,
    required this.settings,
    required this.selectedAmount,
    required this.onChanged,
  });

  final DeliveryTipSettings settings;
  final double selectedAmount;
  final ValueChanged<double> onChanged;

  @override
  State<CheckoutTipSection> createState() => _CheckoutTipSectionState();
}

class _CheckoutTipSectionState extends State<CheckoutTipSection> {
  static const _customKey = -1;
  int? _selectedPreset;
  bool _customMode = false;
  final _customCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncFromAmount(widget.selectedAmount);
  }

  @override
  void didUpdateWidget(CheckoutTipSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedAmount != widget.selectedAmount) {
      _syncFromAmount(widget.selectedAmount);
    }
  }

  void _syncFromAmount(double amount) {
    final rounded = amount.round();
    if (rounded <= 0) {
      _selectedPreset = null;
      _customMode = false;
      _customCtrl.clear();
      return;
    }
    final idx = widget.settings.suggestedTips.indexOf(rounded);
    if (idx >= 0) {
      _selectedPreset = rounded;
      _customMode = false;
      _customCtrl.clear();
    } else {
      _selectedPreset = _customKey;
      _customMode = true;
      _customCtrl.text = rounded.toString();
    }
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _selectPreset(int amount) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPreset = amount;
      _customMode = false;
      _customCtrl.clear();
    });
    widget.onChanged(amount.toDouble());
  }

  void _selectCustom() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPreset = _customKey;
      _customMode = true;
    });
  }

  void _applyCustom() {
    final v = int.tryParse(_customCtrl.text.trim()) ?? 0;
    if (v <= 0) {
      widget.onChanged(0);
      return;
    }
    final capped = v.clamp(0, widget.settings.maxTipAmount);
    widget.onChanged(capped.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.settings.enabled) return const SizedBox.shrink();

    final presets = widget.settings.suggestedTips;

    return FadeInUp(
      duration: AppMotion.medium,
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppSurface.of(context).card,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColor.primary.withValues(alpha: 0.35)),
          boxShadow: AppShadow.dim,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFE6A800),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tip Your Delivery Partner',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '100% of your tip goes directly to the delivery partner.',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: AppSurface.of(context).textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final amount in presets)
                  _TipChip(
                    label: '₹$amount',
                    selected: _selectedPreset == amount,
                    onTap: () => _selectPreset(amount),
                  ),
                _TipChip(
                  label: 'Custom',
                  selected: _selectedPreset == _customKey,
                  onTap: _selectCustom,
                ),
              ],
            ),
            if (_customMode) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _customCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Enter amount (max ₹${widget.settings.maxTipAmount})',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                onSubmitted: (_) => _applyCustom(),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _applyCustom,
                  child: const Text('Apply'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  const _TipChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.short,
      curve: AppMotion.emphasized,
      child: Material(
        color: selected
            ? AppColor.primary.withValues(alpha: 0.2)
            : AppSurface.of(context).subtle,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? AppColor.primary
                    : AppSurface.of(context).border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? AppSurface.of(context).text : AppSurface.of(context).textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
