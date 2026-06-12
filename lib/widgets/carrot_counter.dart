import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A persistent carrot counter. Each card mined = +1 🥕.
/// Collect enough carrots and the bunny "evolves".
class CarrotCounter extends StatefulWidget {
  const CarrotCounter({super.key});

  @override
  State<CarrotCounter> createState() => CarrotCounterState();
}

class CarrotCounterState extends State<CarrotCounter>
    with SingleTickerProviderStateMixin {
  int _carrots = 0;
  late AnimationController _bumpController;
  late Animation<double> _bump;

  @override
  void initState() {
    super.initState();
    _loadCarrots();
    _bumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bump = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _bumpController, curve: Curves.elasticOut),
    );
  }

  Future<void> _loadCarrots() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _carrots = prefs.getInt('carrot_count') ?? 0);
  }

  Future<void> addCarrot() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _carrots++);
    await prefs.setInt('carrot_count', _carrots);
    _bumpController.forward(from: 0);
  }

  String get _evolutionStage {
    if (_carrots >= 100) return '🐰👑';
    if (_carrots >= 50) return '🐰💫';
    if (_carrots >= 25) return '🐰🎀';
    if (_carrots >= 10) return '🐰✨';
    if (_carrots >= 5) return '🐰';
    return '🐇';
  }

  String get stageName {
    if (_carrots >= 100) return 'Bunny Overlord';
    if (_carrots >= 50) return 'Cosmic Bunny';
    if (_carrots >= 25) return 'Fancy Bunny';
    if (_carrots >= 10) return 'Sparkle Bunny';
    if (_carrots >= 5) return 'Bunny';
    return 'Baby Bunny';
  }

  @override
  void dispose() {
    _bumpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bump,
      builder: (context, child) {
        return Transform.scale(
          scale: _bump.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8A0BF), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE8A0BF).withAlpha(40),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _evolutionStage,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 6),
                Text(
                  '$_carrots 🥕',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE8A0BF),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
