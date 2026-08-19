import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';

import '../../domain/order_models.dart';

/// Animated ETA pill — shows remaining minutes for a live order. Hidden
/// for delivered/cancelled orders.
class EtaPill extends StatelessWidget {
  const EtaPill({super.key, required this.eta, required this.status});

  final Duration eta;
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == OrderStatus.delivered || status == OrderStatus.cancelled) {
      return const SizedBox.shrink();
    }

    final minutes = (eta.inSeconds / 60).round().clamp(1, 90);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, t, _) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - t)),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black, Colors.grey.shade900],
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, color: AppColor.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Arriving in $minutes min',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
