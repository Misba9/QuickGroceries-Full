import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/loading/loading.dart';

class OrderActionsBar extends StatelessWidget {
  const OrderActionsBar({
    super.key,
    required this.onReorder,
    required this.onInvoice,
    required this.onSupport,
    this.busyAction,
  });

  final VoidCallback onReorder;
  final VoidCallback onInvoice;
  final VoidCallback onSupport;

  /// One of `reorder` / `invoice` / `support` while a side-effect runs.
  final String? busyAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.refresh_rounded,
            label: 'Reorder',
            primary: true,
            isLoading: busyAction == 'reorder',
            onTap: onReorder,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.receipt_long_rounded,
            label: 'Invoice',
            isLoading: busyAction == 'invoice',
            onTap: onInvoice,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.support_agent_rounded,
            label: 'Need help',
            onTap: onSupport,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    final bg = primary ? AppColor.primary : surface.card;
    final fg = primary ? Colors.black : surface.textPrimary;
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: primary ? AppColor.primary : surface.border,
          ),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(width: 18, height: 18, child: AppLoading.micro)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
