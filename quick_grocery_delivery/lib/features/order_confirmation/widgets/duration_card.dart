import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';

class TimeRangeCard extends StatelessWidget {
  const TimeRangeCard({
    Key? key,
    required this.time,
    required this.duration,
    required this.distance,
  }) : super(key: key);
  final String time;
  final String duration;
  final String distance;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              '$duration min',
              style: const TextStyle(
                color: GlobalVariables.secondary,
                fontSize: 22,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              time,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: GlobalVariables.secondary.withOpacity(0.3),
          ),
          child: Center(
            child: Text(
              distance,
              style: const TextStyle(
                fontSize: 16,
                color: GlobalVariables.secondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
