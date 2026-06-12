import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_sentence/services/streak_service.dart';

void main() {
  group('StreakService', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    StreakService makeService() => StreakService(prefs);

    test('starts at zero streak with no history', () {
      final service = makeService();
      expect(service.currentStreak, 0);
      expect(service.bestStreak, 0);
      expect(service.cardsToday, 0);
      expect(service.lastActiveDate, isNull);
    });

    test('first card starts a streak of 1', () async {
      final service = makeService();
      final update = await service.recordCardGenerated();

      expect(update.currentStreak, 1);
      expect(update.streakExtended, isFalse);
      expect(update.streakReset, isTrue); // no prior date = gap = reset
      expect(update.milestoneReached, isFalse);
      expect(update.cardsToday, 1);
      expect(service.currentStreak, 1);
      expect(service.bestStreak, 1);
    });

    test('second card same day does not extend streak', () async {
      final service = makeService();
      await service.recordCardGenerated(); // day 1, card 1
      final update = await service.recordCardGenerated(); // day 1, card 2

      expect(update.currentStreak, 1);
      expect(update.streakExtended, isFalse);
      expect(update.cardsToday, 2);
      expect(service.currentStreak, 1);
    });

    test('card next day extends streak', () async {
      // Simulate yesterday's card
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${_pad(yesterday.month)}-${_pad(yesterday.day)}';
      await prefs.setInt('streak_current_count', 5);
      await prefs.setInt('streak_best_count', 5);
      await prefs.setString('streak_last_active_date', yesterdayStr);

      final service = makeService();
      final update = await service.recordCardGenerated();

      expect(update.currentStreak, 6);
      expect(update.streakExtended, isTrue);
      expect(update.streakReset, isFalse);
      expect(service.currentStreak, 6);
      expect(service.bestStreak, 6);
    });

    test('gap in days resets streak to 1', () async {
      // Simulate a card from 3 days ago
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final dateStr =
          '${threeDaysAgo.year}-${_pad(threeDaysAgo.month)}-${_pad(threeDaysAgo.day)}';
      await prefs.setInt('streak_current_count', 10);
      await prefs.setInt('streak_best_count', 10);
      await prefs.setString('streak_last_active_date', dateStr);

      final service = makeService();
      final update = await service.recordCardGenerated();

      expect(update.currentStreak, 1);
      expect(update.streakExtended, isFalse);
      expect(update.streakReset, isTrue);
      expect(service.currentStreak, 1);
      // Best streak should still be 10
      expect(service.bestStreak, 10);
    });

    test('best streak is preserved across resets', () async {
      // Build up to 7, then extend to 8
      await prefs.setInt('streak_current_count', 7);
      await prefs.setInt('streak_best_count', 7);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${_pad(yesterday.month)}-${_pad(yesterday.day)}';
      await prefs.setString('streak_last_active_date', yesterdayStr);

      final service = makeService();
      await service.recordCardGenerated(); // extends to 8

      expect(service.currentStreak, 8);
      expect(service.bestStreak, 8);

      // Now simulate a gap and reset
      final fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5));
      final gapStr =
          '${fiveDaysAgo.year}-${_pad(fiveDaysAgo.month)}-${_pad(fiveDaysAgo.day)}';
      await prefs.setInt('streak_current_count', 8);
      await prefs.setString('streak_last_active_date', gapStr);

      final service2 = makeService();
      await service2.recordCardGenerated();

      expect(service2.currentStreak, 1);
      expect(service2.bestStreak, 8); // best preserved
    });

    test('milestone at 3 days', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${_pad(yesterday.month)}-${_pad(yesterday.day)}';
      await prefs.setInt('streak_current_count', 2);
      await prefs.setString('streak_last_active_date', yesterdayStr);

      final service = makeService();
      final update = await service.recordCardGenerated();

      expect(update.currentStreak, 3);
      expect(update.milestoneReached, isTrue);
      expect(service.isMilestoneDay(3), isTrue);
    });

    test('milestone at 7 days', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${_pad(yesterday.month)}-${_pad(yesterday.day)}';
      await prefs.setInt('streak_current_count', 6);
      await prefs.setString('streak_last_active_date', yesterdayStr);

      final service = makeService();
      final update = await service.recordCardGenerated();

      expect(update.currentStreak, 7);
      expect(update.milestoneReached, isTrue);
    });

    test('milestone at 30 days', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${_pad(yesterday.month)}-${_pad(yesterday.day)}';
      await prefs.setInt('streak_current_count', 29);
      await prefs.setString('streak_last_active_date', yesterdayStr);

      final service = makeService();
      final update = await service.recordCardGenerated();

      expect(update.currentStreak, 30);
      expect(update.milestoneReached, isTrue);
    });

    test('non-milestone days do not trigger milestone', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${_pad(yesterday.month)}-${_pad(yesterday.day)}';
      await prefs.setInt('streak_current_count', 4);
      await prefs.setString('streak_last_active_date', yesterdayStr);

      final service = makeService();
      final update = await service.recordCardGenerated();

      expect(update.currentStreak, 5);
      expect(update.milestoneReached, isFalse);
    });

    test('milestone messages for all thresholds', () {
      for (final threshold in StreakService.milestones) {
        final msg = StreakService.milestoneMessage(threshold);
        expect(msg, isNotEmpty);
        expect(msg, contains('🐰'));
      }
    });

    test('milestone message for non-milestone', () {
      final msg = StreakService.milestoneMessage(5);
      expect(msg, contains('5 day streak'));
      expect(msg, contains('🐰'));
    });

    test('reset clears all streak data', () async {
      final service = makeService();
      await service.recordCardGenerated();
      await service.recordCardGenerated();

      expect(service.currentStreak, 1);
      expect(service.cardsToday, 2);

      await service.reset();

      expect(service.currentStreak, 0);
      expect(service.cardsToday, 0);
      expect(service.lastActiveDate, isNull);
    });

    test('hasEvent is true when streak extended', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${_pad(yesterday.month)}-${_pad(yesterday.day)}';
      await prefs.setInt('streak_current_count', 3);
      await prefs.setString('streak_last_active_date', yesterdayStr);

      final service = makeService();
      final update = await service.recordCardGenerated();

      expect(update.hasEvent, isTrue);
    });

    test('hasEvent is false for same-day second card', () async {
      final service = makeService();
      await service.recordCardGenerated();
      final update = await service.recordCardGenerated();

      expect(update.hasEvent, isFalse);
    });
  });
}

String _pad(int n) => n.toString().padLeft(2, '0');
