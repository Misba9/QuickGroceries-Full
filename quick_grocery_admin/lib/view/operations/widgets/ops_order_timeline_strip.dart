import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/view/operations/models/ops_dashboard_models.dart';

/// Horizontal order lifecycle timeline.
class OpsOrderTimelineStrip extends StatelessWidget {
  const OpsOrderTimelineStrip({super.key, required this.timeline});

  final Map<OpsTimelineStep, bool> timeline;

  static const _steps = <(OpsTimelineStep, String)>[
    (OpsTimelineStep.placed, 'Placed'),
    (OpsTimelineStep.accepted, 'Accepted'),
    (OpsTimelineStep.preparing, 'Preparing'),
    (OpsTimelineStep.pickedUp, 'Picked Up'),
    (OpsTimelineStep.delivered, 'Delivered'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: timeline[_steps[i - 1].$1] == true &&
                        timeline[_steps[i].$1] == true
                    ? const Color(0xFF047857)
                    : Colors.grey.shade300,
              ),
            ),
          _StepDot(
            label: _steps[i].$2,
            done: timeline[_steps[i].$1] == true,
            active: timeline[_steps[i].$1] == true &&
                (i == _steps.length - 1 ||
                    timeline[_steps[i + 1].$1] != true),
          ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.label,
    required this.done,
    required this.active,
  });

  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: done ? const Color(0xFF047857) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: done ? const Color(0xFF047857) : Colors.grey.shade400,
              width: 2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: done ? const Color(0xFF334155) : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
