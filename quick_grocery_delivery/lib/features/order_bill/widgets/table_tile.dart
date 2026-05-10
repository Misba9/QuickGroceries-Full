import 'package:flutter/material.dart';

class TableTile extends StatelessWidget {
  const TableTile({
    Key? key,
    required this.title,
    required this.value,
    required this.isTitle,
  }) : super(key: key);
  final String title;
  final String value;
  final bool isTitle;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isTitle ? 18 : 16,
              fontWeight: isTitle ? FontWeight.bold : null,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTitle ? 18 : 16,
              fontWeight: isTitle ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }
}
