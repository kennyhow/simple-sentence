import 'package:shared_preferences/shared_preferences.dart';

/// Tracks daily mining streaks with milestone celebrations.
///
/// A "day" is counted when the user generates at least one card.
/// Streaks reset if a full calendar day passes with no activity.
class StreakService {
  static const _keyCurrentStreak = 'streak_current_count';
  static const _keyLastActiveDate = 'streak_last_active_date';
  static const _keyBestStreak = 'streak_best_count';
  static const _keyCardsToday = 'streak_cards_today';

  /// Milestone thresholds that trigger celebrations.
  static const milestones = {3, 7, 14, 30, 60, 100, 200, 365};

  final SharedPreferences _prefs;

  StreakService(this._prefs);

  static Future<StreakService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StreakService(prefs);
  }

  /// Current consecutive days with at least one card generated.
  int get currentStreak => _prefs.getInt(_keyCurrentStreak) ?? 0;

  /// All-time best streak.
  int get bestStreak => _prefs.getInt(_keyBestStreak) ?? 0;

  /// Cards generated today.
  int get cardsToday => _prefs.getInt(_keyCardsToday) ?? 0;

  /// The last date (YYYY-MM-DD) a card was generated.
  String? get lastActiveDate => _prefs.getString(_keyLastActiveDate);

  /// Whether today is a milestone day (just reached a milestone).
  bool isMilestoneDay(int streak) => milestones.contains(streak);

  /// Milestone celebration message for a given streak count.
  static String milestoneMessage(int streak) {
    switch (streak) {
      case 3:
        return '3-day streak! The bunny is proud! 🐰✨';
      case 7:
        return 'One week streak! You\'re on fire! 🔥🐰';
      case 14:
        return 'Two weeks! The bunny evolved! 🐰💫';
      case 30:
        return 'A whole month! Legendary dedication! 👑🐰';
      case 60:
        return '60 days! The bunny bows to you! 🙇🐰';
      case 100:
        return '100 DAY STREAK! You ARE the bunny! 🐰🌈';
      case 200:
        return '200 days! Bunny Overlord status achieved! 🐰👑⚡';
      case 365:
        return 'ONE YEAR! The ultimate bunny sage! 🐰🏆🎊';
      default:
        return '$streak day streak! Keep going! 🐰🥕';
    }
  }

  /// Record a card generation. Updates streak and returns a [StreakUpdate]
  /// describing what changed.
  Future<StreakUpdate> recordCardGenerated() async {
    final today = _todayString();
    final lastDate = _prefs.getString(_keyLastActiveDate);
    final yesterday = _yesterdayString();

    var current = _prefs.getInt(_keyCurrentStreak) ?? 0;
    var best = _prefs.getInt(_keyBestStreak) ?? 0;
    final cardsSoFar = _prefs.getInt(_keyCardsToday) ?? 0;

    bool streakExtended = false;
    bool streakReset = false;
    bool milestoneReached = false;
    int newStreak = current;

    if (lastDate == null || lastDate != today) {
      // New day — check if streak continues or resets
      if (lastDate == yesterday) {
        // Consecutive day — extend streak
        newStreak = current + 1;
        streakExtended = true;
        if (isMilestoneDay(newStreak)) {
          milestoneReached = true;
        }
      } else if (lastDate == today) {
        // Same day, already counted — just increment cards
        newStreak = current;
      } else {
        // Gap — reset streak
        newStreak = 1;
        streakReset = true;
      }

      // Update best streak
      if (newStreak > best) {
        best = newStreak;
        await _prefs.setInt(_keyBestStreak, best);
      }

      await _prefs.setInt(_keyCurrentStreak, newStreak);
      await _prefs.setString(_keyLastActiveDate, today);
      await _prefs.setInt(_keyCardsToday, 1);
    } else {
      // Same day — just increment card count
      await _prefs.setInt(_keyCardsToday, cardsSoFar + 1);
    }

    return StreakUpdate(
      currentStreak: newStreak,
      bestStreak: best,
      cardsToday: lastDate == today ? cardsSoFar + 1 : 1,
      streakExtended: streakExtended,
      streakReset: streakReset,
      milestoneReached: milestoneReached,
    );
  }

  /// Reset the streak (for testing or manual reset).
  Future<void> reset() async {
    await _prefs.remove(_keyCurrentStreak);
    await _prefs.remove(_keyLastActiveDate);
    await _prefs.remove(_keyCardsToday);
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${_pad(now.month)}-${_pad(now.day)}';
  }

  String _yesterdayString() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return '${yesterday.year}-${_pad(yesterday.month)}-${_pad(yesterday.day)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

/// Result of recording a card generation.
class StreakUpdate {
  final int currentStreak;
  final int bestStreak;
  final int cardsToday;
  final bool streakExtended;
  final bool streakReset;
  final bool milestoneReached;

  StreakUpdate({
    required this.currentStreak,
    required this.bestStreak,
    required this.cardsToday,
    this.streakExtended = false,
    this.streakReset = false,
    this.milestoneReached = false,
  });

  /// Whether this update represents any notable event.
  bool get hasEvent => streakExtended || streakReset || milestoneReached;
}
