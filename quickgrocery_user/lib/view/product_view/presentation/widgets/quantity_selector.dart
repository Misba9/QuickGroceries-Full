import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/constants/app_color.dart';

/// Compact +/- quantity stepper used by the cart action bar.
class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    this.disabled = false,
  });

  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final color = disabled ? Colors.grey.shade300 : AppColor.primary;
    return Container(
      decoration: BoxDecoration(
        color: AppColor.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Step(
            icon: Icons.remove_rounded,
            color: color,
            onTap: disabled ? null : onDecrement,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Padding(
              key: ValueKey(value),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '$value',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          _Step(
            icon: Icons.add_rounded,
            color: color,
            onTap: disabled ? null : onIncrement,
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 42,
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
