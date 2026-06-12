import 'dart:math';
import 'package:flutter/material.dart';

/// The bunny mascot — a custom-painted bunny with idle/hop/celebrate states.
///
/// Usage:
///   BunnyMascot(state: BunnyState.idle)
///   BunnyMascot(state: BunnyState.hop)
///   BunnyMascot(state: BunnyState.celebrate)
enum BunnyState { idle, hop, celebrate, sleeping }

class BunnyMascot extends StatefulWidget {
  final BunnyState state;
  final double size;
  final VoidCallback? onTap;
  final String? speechBubble;
  final VoidCallback? onSecretTap;

  const BunnyMascot({
    super.key,
    this.state = BunnyState.idle,
    this.size = 80,
    this.onTap,
    this.speechBubble,
    this.onSecretTap,
  });

  @override
  State<BunnyMascot> createState() => _BunnyMascotState();
}

class _BunnyMascotState extends State<BunnyMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounce;
  late Animation<double> _wiggle;
  late Animation<double> _spin;
  int _tapCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _bounce = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _wiggle = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _spin = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1, curve: Curves.easeOutBack),
      ),
    );

    // Idle breathing animation
    if (widget.state == BunnyState.idle ||
        widget.state == BunnyState.sleeping) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BunnyMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      switch (widget.state) {
        case BunnyState.idle:
        case BunnyState.sleeping:
          _controller.repeat(reverse: true);
          break;
        case BunnyState.hop:
          _controller.forward(from: 0);
          break;
        case BunnyState.celebrate:
          _controller
            ..duration = const Duration(milliseconds: 600)
            ..repeat(reverse: true);
          break;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _tapCount++;
    widget.onTap?.call();

    // Secret: 10 taps triggers a mini celebration
    if (_tapCount >= 10) {
      _tapCount = 0;
      widget.onSecretTap?.call();
      _controller
        ..duration = const Duration(milliseconds: 400)
        ..repeat(reverse: true, period: const Duration(milliseconds: 400));
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _controller
            ..duration = const Duration(milliseconds: 800)
            ..repeat(reverse: true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final bounceVal = _bounce.value;
          final wiggleVal = _wiggle.value;
          final spinVal = _spin.value;
          final isSleeping = widget.state == BunnyState.sleeping;

          return Transform.translate(
            offset: Offset(
              sin(wiggleVal * pi * 2) * 3,
              -bounceVal * 15 * (isSleeping ? 0.1 : 1),
            ),
            child: Transform.rotate(
              angle: sin(spinVal * pi * 2) * 0.15,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _BunnyPainter(
                        state: widget.state,
                        animationValue: _controller.value,
                        isSleeping: isSleeping,
                      ),
                    ),
                    if (widget.speechBubble != null)
                      Positioned(
                        top: -28,
                        right: -10,
                        child: _SpeechBubble(text: widget.speechBubble!),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BunnyPainter extends CustomPainter {
  final BunnyState state;
  final double animationValue;
  final bool isSleeping;

  _BunnyPainter({
    required this.state,
    required this.animationValue,
    required this.isSleeping,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final bodyPaint = Paint()
      ..color = const Color(0xFFFFF0F5) // lavender blush
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = const Color(0xFFE8A0BF) // soft pink outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final earInnerPaint = Paint()
      ..color = const Color(0xFFFFD6E0) // lighter pink
      ..style = PaintingStyle.fill;

    final eyePaint = Paint()
      ..color = const Color(0xFF4A3728)
      ..style = PaintingStyle.fill;

    final nosePaint = Paint()
      ..color = const Color(0xFFFF8FAB)
      ..style = PaintingStyle.fill;

    final blushPaint = Paint()
      ..color = const Color(0xFFFFB6C1).withAlpha(120)
      ..style = PaintingStyle.fill;

    // --- Ears ---
    final earWobble = sin(animationValue * pi * 2) * 3;
    final leftEarPath = Path()
      ..moveTo(cx - 18, cy - 10)
      ..quadraticBezierTo(cx - 28, cy - 50 + earWobble, cx - 22, cy - 70 + earWobble)
      ..quadraticBezierTo(cx - 16, cy - 50 + earWobble, cx - 12, cy - 10);
    canvas.drawPath(leftEarPath, bodyPaint);
    canvas.drawPath(leftEarPath, outlinePaint);

    // Left ear inner
    final leftEarInner = Path()
      ..moveTo(cx - 17, cy - 14)
      ..quadraticBezierTo(cx - 24, cy - 45 + earWobble, cx - 20, cy - 60 + earWobble)
      ..quadraticBezierTo(cx - 17, cy - 45 + earWobble, cx - 14, cy - 14);
    canvas.drawPath(leftEarInner, earInnerPaint);

    final rightEarPath = Path()
      ..moveTo(cx + 12, cy - 10)
      ..quadraticBezierTo(cx + 22, cy - 50 - earWobble, cx + 16, cy - 70 - earWobble)
      ..quadraticBezierTo(cx + 10, cy - 50 - earWobble, cx + 6, cy - 10);
    canvas.drawPath(rightEarPath, bodyPaint);
    canvas.drawPath(rightEarPath, outlinePaint);

    final rightEarInner = Path()
      ..moveTo(cx + 13, cy - 14)
      ..quadraticBezierTo(cx + 20, cy - 45 - earWobble, cx + 16, cy - 60 - earWobble)
      ..quadraticBezierTo(cx + 13, cy - 45 - earWobble, cx + 10, cy - 14);
    canvas.drawPath(rightEarInner, earInnerPaint);

    // --- Body (fluffy circle) ---
    final bodyCenter = Offset(cx, cy + 8);
    canvas.drawCircle(bodyCenter, 22, bodyPaint);
    canvas.drawCircle(bodyCenter, 22, outlinePaint);

    // Fluffy tufts
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * pi * 2 + animationValue * 0.5;
      final tx = bodyCenter.dx + cos(angle) * 24;
      final ty = bodyCenter.dy + sin(angle) * 24;
      canvas.drawCircle(Offset(tx, ty), 4, bodyPaint);
    }

    // --- Eyes ---
    if (isSleeping) {
      // Sleeping: closed eyes (arcs)
      final eyeLinePaint = Paint()
        ..color = const Color(0xFF4A3728)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx - 8, cy + 4), width: 8, height: 6),
        pi, pi, false, eyeLinePaint,
      );
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx + 8, cy + 4), width: 8, height: 6),
        pi, pi, false, eyeLinePaint,
      );
      // Zzz
      final zPaint = Paint()
        ..color = const Color(0xFFB8A0C0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      _drawZ(canvas, Offset(cx + 18, cy - 20), 6, zPaint);
      _drawZ(canvas, Offset(cx + 24, cy - 30), 8, zPaint);
      _drawZ(canvas, Offset(cx + 32, cy - 42), 10, zPaint);
    } else {
      // Open eyes
      canvas.drawCircle(Offset(cx - 8, cy + 4), 3.5, eyePaint);
      canvas.drawCircle(Offset(cx + 8, cy + 4), 3.5, eyePaint);
      // Eye shine
      final shinePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx - 7, cy + 3), 1.2, shinePaint);
      canvas.drawCircle(Offset(cx + 9, cy + 3), 1.2, shinePaint);
    }

    // --- Nose ---
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 8), width: 5, height: 4),
      nosePaint,
    );

    // --- Blush ---
    canvas.drawCircle(Offset(cx - 14, cy + 10), 5, blushPaint);
    canvas.drawCircle(Offset(cx + 14, cy + 10), 5, blushPaint);

    // --- Mouth ---
    final mouthPaint = Paint()
      ..color = const Color(0xFF4A3728)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    if (state == BunnyState.celebrate) {
      // Happy open mouth
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, cy + 12), width: 8, height: 6),
        0, pi, false, mouthPaint,
      );
    } else if (isSleeping) {
      // Tiny relaxed mouth
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, cy + 12), width: 5, height: 3),
        0, pi, false, mouthPaint,
      );
    } else {
      // Small smile
      final mouthPath = Path()
        ..moveTo(cx - 3, cy + 11)
        ..quadraticBezierTo(cx, cy + 14, cx + 3, cy + 11);
      canvas.drawPath(mouthPath, mouthPaint);
    }

    // --- Whiskers ---
    final whiskerPaint = Paint()
      ..color = const Color(0xFFD4A0B0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    // Left whiskers
    canvas.drawLine(
        Offset(cx - 16, cy + 8), Offset(cx - 28, cy + 4), whiskerPaint);
    canvas.drawLine(
        Offset(cx - 16, cy + 10), Offset(cx - 28, cy + 12), whiskerPaint);
    // Right whiskers
    canvas.drawLine(
        Offset(cx + 16, cy + 8), Offset(cx + 28, cy + 4), whiskerPaint);
    canvas.drawLine(
        Offset(cx + 16, cy + 10), Offset(cx + 28, cy + 12), whiskerPaint);

    // --- Little paws ---
    canvas.drawCircle(Offset(cx - 10, cy + 26), 5, bodyPaint);
    canvas.drawCircle(Offset(cx - 10, cy + 26), 5, outlinePaint);
    canvas.drawCircle(Offset(cx + 10, cy + 26), 5, bodyPaint);
    canvas.drawCircle(Offset(cx + 10, cy + 26), 5, outlinePaint);

    // --- Tail (fluffy pom) ---
    canvas.drawCircle(Offset(cx + 22, cy + 20), 7, bodyPaint);
    canvas.drawCircle(Offset(cx + 22, cy + 20), 7, outlinePaint);
  }

  void _drawZ(Canvas canvas, Offset pos, double size, Paint paint) {
    final path = Path()
      ..moveTo(pos.dx - size / 2, pos.dy - size / 2)
      ..lineTo(pos.dx + size / 2, pos.dy - size / 2)
      ..lineTo(pos.dx - size / 2, pos.dy + size / 2)
      ..lineTo(pos.dx + size / 2, pos.dy + size / 2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BunnyPainter oldDelegate) =>
      state != oldDelegate.state ||
      animationValue != oldDelegate.animationValue ||
      isSleeping != oldDelegate.isSleeping;
}

class _SpeechBubble extends StatelessWidget {
  final String text;
  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8A0BF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE8A0BF).withAlpha(60),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF4A3728),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
