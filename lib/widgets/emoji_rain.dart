import 'dart:math';
import 'package:flutter/material.dart';

/// Emoji rain overlay — bunnies, carrots, and sparkles fall from the top.
///
/// Usage:
///   EmojiRain.show(context) — trigger a burst
///   Or wrap your screen with EmojiRainOverlay(child: ...)
class EmojiRainOverlay extends StatefulWidget {
  final Widget child;
  final bool active;

  const EmojiRainOverlay({
    super.key,
    required this.child,
    this.active = false,
  });

  /// Show a one-shot emoji rain burst.
  static void show(BuildContext context) {
    final overlay = context.findAncestorStateOfType<EmojiRainOverlayState>();
    overlay?.trigger();
  }

  @override
  State<EmojiRainOverlay> createState() => EmojiRainOverlayState();
}

class EmojiRainOverlayState extends State<EmojiRainOverlay>
    with SingleTickerProviderStateMixin {
  final List<_EmojiParticle> _particles = [];
  final _random = Random();
  late AnimationController _controller;
  bool _bursting = false;

  static const _emojis = [
    '🐰', '🐇', '🐰', '🐇', '🐰',
    '🥕', '🥕', '🥕',
    '🌸', '🌸',
    '✨', '💖', '🎀',
    '🐾',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
        setState(() {
          for (final p in _particles) {
            p.y += p.speed;
            p.x += sin(p.y * 0.05 + p.phase) * 1.5;
            p.rotation += p.rotSpeed;
            p.opacity = p.y > 0.7 ? (1.0 - (p.y - 0.7) / 0.3).clamp(0.0, 1.0) : 1.0;
          }
          _particles.removeWhere((p) => p.y > 1.0);
        });
      });
  }

  void trigger() {
    setState(() {
      _bursting = true;
      for (var i = 0; i < 25; i++) {
        _particles.add(_EmojiParticle(
          emoji: _emojis[_random.nextInt(_emojis.length)],
          x: _random.nextDouble(),
          y: -0.1 - _random.nextDouble() * 0.3,
          speed: 0.008 + _random.nextDouble() * 0.015,
          size: 16.0 + _random.nextDouble() * 18,
          rotation: _random.nextDouble() * pi * 2,
          rotSpeed: (_random.nextDouble() - 0.5) * 0.05,
          phase: _random.nextDouble() * pi * 2,
        ));
      }
    });

    _controller.forward(from: 0);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _bursting = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_bursting || _particles.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _EmojiPainter(particles: _particles),
                size: Size.infinite,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmojiParticle {
  final String emoji;
  double x;
  double y;
  final double speed;
  final double size;
  double rotation;
  final double rotSpeed;
  final double phase;
  double opacity = 1.0;

  _EmojiParticle({
    required this.emoji,
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.rotSpeed,
    required this.phase,
  });
}

class _EmojiPainter extends CustomPainter {
  final List<_EmojiParticle> particles;

  _EmojiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final tp = TextPainter(
        text: TextSpan(
          text: p.emoji,
          style: TextStyle(fontSize: p.size),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.saveLayer(
        Rect.fromCenter(
          center: Offset(p.x * size.width, p.y * size.height),
          width: tp.width + 4,
          height: tp.height + 4,
        ),
        Paint()..color = Colors.white.withValues(alpha: p.opacity),
      );
      canvas.translate(p.x * size.width, p.y * size.height);
      canvas.rotate(p.rotation);
      tp.paint(
        canvas,
        Offset(-tp.width / 2, -tp.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _EmojiPainter oldDelegate) => true;
}
