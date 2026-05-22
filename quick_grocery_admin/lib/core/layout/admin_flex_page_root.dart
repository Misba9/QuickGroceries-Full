import 'package:flutter/material.dart';

/// Root for flex admin pages — replaces nested [Scaffold] + unbounded [Center].
class AdminFlexPageRoot extends StatelessWidget {
  const AdminFlexPageRoot({
    super.key,
    required this.child,
    this.backgroundColor = const Color(0xFFFFFAF0),
  });

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: child,
    );
  }
}
