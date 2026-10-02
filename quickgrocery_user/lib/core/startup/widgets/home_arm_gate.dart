import 'package:flutter/material.dart';

import 'package:quickgrocery/core/loading/loading_constants.dart';
import 'package:quickgrocery/core/startup/post_home_startup.dart';

/// Mounts [child] only after [PostHomeStartup] has reached [frame].
/// Until then shows [placeholder] (typically a section shimmer).
///
/// Soft crossfade when arming so deferred sections don't "pop" onto Home.
class HomeArmGate extends StatefulWidget {
  const HomeArmGate({
    super.key,
    required this.frame,
    required this.child,
    this.placeholder = const SizedBox.shrink(),
  });

  final int frame;
  final Widget child;
  final Widget placeholder;

  @override
  State<HomeArmGate> createState() => _HomeArmGateState();
}

class _HomeArmGateState extends State<HomeArmGate> {
  late bool _armed;

  @override
  void initState() {
    super.initState();
    _armed = PostHomeStartup.armedAt(widget.frame);
    if (!_armed) {
      PostHomeStartup.elapsedFrames.addListener(_onTick);
      PostHomeStartup.homeVisible.addListener(_onTick);
    }
  }

  void _onTick() {
    if (!mounted) return;
    if (PostHomeStartup.armedAt(widget.frame)) {
      PostHomeStartup.elapsedFrames.removeListener(_onTick);
      PostHomeStartup.homeVisible.removeListener(_onTick);
      setState(() => _armed = true);
    }
  }

  @override
  void dispose() {
    PostHomeStartup.elapsedFrames.removeListener(_onTick);
    PostHomeStartup.homeVisible.removeListener(_onTick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      return _armed ? widget.child : widget.placeholder;
    }

    return AnimatedSwitcher(
      duration: LoadingConstants.armReveal,
      switchInCurve: LoadingConstants.revealCurve,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.025),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: LoadingConstants.revealCurve,
            )),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<bool>(_armed),
        child: _armed ? widget.child : widget.placeholder,
      ),
    );
  }
}
