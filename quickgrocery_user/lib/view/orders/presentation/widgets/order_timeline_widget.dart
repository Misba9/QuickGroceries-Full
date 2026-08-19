import 'package:flutter/material.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:intl/intl.dart';
import 'package:quickgrocery/constants/app_color.dart';

import '../../domain/order_models.dart';

class OrderTimelineWidget extends StatelessWidget {
  const OrderTimelineWidget({super.key, required this.entries});

  final List<OrderTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < entries.length; i++)
            _TimelineRow(
              entry: entries[i],
              isLast: i == entries.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.isLast});

  final OrderTimelineEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = entry.done
        ? (entry.active ? AppColor.primary : Colors.green.shade600)
        : Colors.grey.shade300;
    final icon = entry.done ? Icons.check_rounded : Icons.circle;
    final iconColor = entry.done ? Colors.white : Colors.grey.shade500;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: entry.active
                    ? [
                        BoxShadow(
                          color: AppColor.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, color: iconColor, size: entry.done ? 18 : 8),
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Dash(
                  direction: Axis.vertical,
                  length: 36,
                  dashLength: 6,
                  dashThickness: 2,
                  dashColor:
                      entry.done ? Colors.green.shade300 : Colors.grey.shade300,
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: entry.done ? Colors.black : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    if (entry.at != null)
                      Text(
                        DateFormat('hh:mm a').format(entry.at!),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entry.subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
