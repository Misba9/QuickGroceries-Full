import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/constants/app_icons.dart';

class PrimaryAppBar extends StatelessWidget {
  const PrimaryAppBar({Key? key, required this.width, required this.title})
    : super(key: key);

  final double width;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            height: width * .12,
            width: width * .12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.black,
            ),
            child: Center(child: Image.asset(AppIcons.arrowBack)),
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(width: width * .12),
      ],
    );
  }
}
