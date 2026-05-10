import 'package:flutter/material.dart';

import 'package:quick_grocery_delivery/constants/global_variables.dart';

class SocialMediaIcon extends StatelessWidget {
  const SocialMediaIcon({Key? key, required this.width, required this.icon})
    : super(key: key);

  final double width;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      height: width * .12,
      width: width * .12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GlobalVariables.lightGrey),
      ),
      child: Center(child: Image.asset(icon)),
    );
  }
}
