import 'package:flutter/material.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';

/// Animated "AI is typing…" bubble with bouncing dots.
class AiTypingIndicator extends StatefulWidget {
  const AiTypingIndicator({super.key});

  @override
  State<AiTypingIndicator> createState() => _AiTypingIndicatorState();
}

class _AiTypingIndicatorState extends State<AiTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final surface = AppSurface.of(context);

    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColor.primary.withValues(alpha: 0.2),
          child: const Icon(Icons.smart_toy_rounded, size: 16),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: surface.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: surface.border),
          ),
          child: reduce
              ? Text(
                  'AI is typing…',
                  style: TextStyle(color: surface.textMuted, fontSize: 13),
                )
              : AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final t = (_c.value + i * 0.2) % 1.0;
                        final dy = (t < 0.5 ? t : 1 - t) * -6;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Transform.translate(
                            offset: Offset(0, dy),
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: surface.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
