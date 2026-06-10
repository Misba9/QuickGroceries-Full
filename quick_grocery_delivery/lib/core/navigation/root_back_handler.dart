import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Handles Android system back for root shells:
/// - pops pushed routes first
/// - returns to [defaultTabIndex] when nested tabs are active
/// - requires a second back press within [exitGracePeriod] to exit
class RootBackHandler extends StatefulWidget {
  const RootBackHandler({
    super.key,
    required this.child,
    this.selectedTabIndex,
    this.defaultTabIndex = 0,
    this.onTabSelected,
    this.blockPop = false,
    this.exitMessage = 'Press back again to exit',
    this.exitGracePeriod = const Duration(seconds: 2),
  });

  final Widget child;
  final int? selectedTabIndex;
  final int defaultTabIndex;
  final ValueChanged<int>? onTabSelected;
  final bool blockPop;
  final String exitMessage;
  final Duration exitGracePeriod;

  @override
  State<RootBackHandler> createState() => _RootBackHandlerState();
}

class _RootBackHandlerState extends State<RootBackHandler> {
  DateTime? _lastExitRequest;

  void _handlePopInvoked(bool didPop) {
    if (didPop || widget.blockPop) return;

    final navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return;
    }

    final tabIndex = widget.selectedTabIndex;
    final onTabSelected = widget.onTabSelected;
    if (tabIndex != null &&
        onTabSelected != null &&
        tabIndex != widget.defaultTabIndex) {
      onTabSelected(widget.defaultTabIndex);
      return;
    }

    final now = DateTime.now();
    if (_lastExitRequest != null &&
        now.difference(_lastExitRequest!) <= widget.exitGracePeriod) {
      SystemNavigator.pop();
      return;
    }

    _lastExitRequest = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(widget.exitMessage),
          duration: widget.exitGracePeriod,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _handlePopInvoked(didPop),
      child: widget.child,
    );
  }
}
