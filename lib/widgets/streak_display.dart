import 'package:flutter/material.dart';
import '../services/streak_service.dart';

/// Displays the current mining streak with bunny-themed flair.
///
/// Shows the streak count, a fire emoji when active, and triggers
/// milestone celebrations via callbacks.
class StreakDisplay extends StatefulWidget {
  final StreakService streakService;
  final VoidCallback? onMilestoneCelebrate;
  final ValueChanged<String>? onMilestoneMessage;

  const StreakDisplay({
    super.key,
    required this.streakService,
    this.onMilestoneCelebrate,
    this.onMilestoneMessage,
  });

  @override
  State<StreakDisplay> createState() => StreakDisplayState();
}

class StreakDisplayState extends State<StreakDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _bumpController;
  late Animation<double> _bump;

  @override
  void initState() {
    super.initState();
    _bumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bump = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _bumpController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _bumpController.dispose();
    super.dispose();
  }

  /// Trigger a bump animation (call when streak extends).
  void bump() {
    _bumpController.forward(from: 0);
  }

  /// Show a milestone celebration.
  void celebrateMilestone(int streak) {
    _bumpController.forward(from: 0);
    widget.onMilestoneCelebrate?.call();
    widget.onMilestoneMessage?.call(StreakService.milestoneMessage(streak));
  }

  @override
  Widget build(BuildContext context) {
    final streak = widget.streakService.currentStreak;
    final cardsToday = widget.streakService.cardsToday;
    final hasStreak = streak > 0;
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _bump,
      builder: (context, child) {
        return Transform.scale(
          scale: _bump.value,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: hasStreak
                  ? const Color(0xFFFFF3E0)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasStreak
                    ? const Color(0xFFFFCC80)
                    : const Color(0xFFE8A0BF).withAlpha(80),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (hasStreak
                          ? const Color(0xFFFF9800)
                          : const Color(0xFFE8A0BF))
                      .withAlpha(30),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasStreak ? '🔥' : '🐰',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
                Text(
                  hasStreak ? '$streak' : '--',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: hasStreak
                        ? const Color(0xFFE65100)
                        : theme.colorScheme.onSurface.withAlpha(100),
                  ),
                ),
                if (hasStreak) ...[
                  const SizedBox(width: 2),
                  Text(
                    'day${streak == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFFE65100).withAlpha(180),
                    ),
                  ),
                ],
                if (cardsToday > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 16,
                    color: theme.colorScheme.outline.withAlpha(40),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$cardsToday',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withAlpha(180),
                    ),
                  ),
                  Text(
                    ' today',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withAlpha(100),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
