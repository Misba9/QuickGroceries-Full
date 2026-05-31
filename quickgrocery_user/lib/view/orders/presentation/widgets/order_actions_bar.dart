import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';

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
    final bg = primary ? AppColor.primary : Colors.white;
    final fg = Colors.black;
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
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
