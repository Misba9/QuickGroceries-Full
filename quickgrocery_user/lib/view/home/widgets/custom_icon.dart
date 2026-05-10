import 'package:flutter/material.dart';

class CustomIcon extends StatelessWidget {
  const CustomIcon({
    super.key,
    this.color = Colors.black,
    required this.icon,
  });
  final String icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 25,
        child: Image.asset(
          icon,
          color: color,
        ));
  }
}
