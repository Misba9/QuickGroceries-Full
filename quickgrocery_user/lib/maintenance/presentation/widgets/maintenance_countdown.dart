import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

/// Live H:M:S countdown — updates every second without page refresh.
class MaintenanceCountdown extends StatefulWidget {
  const MaintenanceCountdown({
    super.key,
    required this.target,
    this.textColor,
  });

  final DateTime target;
  final Color? textColor;

  @override
  State<MaintenanceCountdown> createState() => _MaintenanceCountdownState();
}

class _MaintenanceCountdownState extends State<MaintenanceCountdown> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(MaintenanceCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) _tick();
  }

  void _tick() {
    final diff = widget.target.difference(DateTime.now());
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.textColor ?? Colors.white;
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);

    return Column(
      children: [
        Text(
          context.l10n.maintenance_reopens_in,
          style: GoogleFonts.poppins(
            color: color.withValues(alpha: 0.85),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Unit(value: h, label: context.l10n.maintenance_hours, color: color),
            _sep(color),
            _Unit(value: m, label: context.l10n.maintenance_minutes, color: color),
            _sep(color),
            _Unit(value: s, label: context.l10n.maintenance_seconds, color: color),
          ],
        ),
      ],
    );
  }

  Widget _sep(Color color) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          ':',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      );
}

class _Unit extends StatelessWidget {
  const _Unit({required this.value, required this.label, required this.color});
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: color.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}
