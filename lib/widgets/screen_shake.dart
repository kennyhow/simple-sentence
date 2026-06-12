import 'package:flutter/material.dart';

/// Wraps a child and shakes it on command.
class ScreenShake extends StatefulWidget {
  final Widget child;
  final GlobalKey<ScreenShakeState>? shakeKey;

  const ScreenShake({
    super.key,
    required this.child,
    this.shakeKey,
  });

  /// Trigger a shake on the nearest ScreenShake ancestor.
  static void trigger(BuildContext context) {
    final state = context.findAncestorStateOfType<ScreenShakeState>();
    state?.shake();
  }

  @override
  State<ScreenShake> createState() => ScreenShakeState();
}

class ScreenShakeState extends State<ScreenShake>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeX;
  late Animation<double> _shakeY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeX = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 4), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 4, end: -4), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4, end: 3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 3, end: -2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -2, end: 1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 1),
    ]).animate(_controller);

    _shakeY = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -3, end: 3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 3, end: -2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -2, end: 1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1, end: -1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -1, end: 0), weight: 1),
    ]).animate(_controller);
  }

  void shake() {
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeX.value, _shakeY.value),
          child: widget.child,
        );
      },
    );
  }
}
