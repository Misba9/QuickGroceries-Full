import 'package:flutter/material.dart';

class DualButton extends StatelessWidget {
  const DualButton({
    Key? key,
    required this.width,
    required this.onTap,
    required this.onTap2,
  }) : super(key: key);

  final double width;
  final Function() onTap;
  final Function() onTap2;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: width * .13,
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                  child: Text(
                'Go to Home',
                style: TextStyle(color: Colors.black, fontSize: 17),
              )),
            ),
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: GestureDetector(
            onTap: onTap2,
            child: Container(
              height: width * .13,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
