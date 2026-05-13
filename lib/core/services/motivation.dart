import 'dart:math';

class MotivationMessage {
  final String title;
  final String body;
  const MotivationMessage(this.title, this.body);
}

/// Categorized motivational messages. The picker chooses based on user state.
class Motivation {
  static const _morning = <MotivationMessage>[
    MotivationMessage('Good morning, athlete', 'How are you feeling today? Tap to check in.'),
    MotivationMessage('Rise and grind', 'A 30-second check-in keeps your streak alive.'),
    MotivationMessage('Today is a new rep', 'Log how you feel and plan your next move.'),
    MotivationMessage('Discipline > motivation', 'Show up. Even rest counts. Tap to check in.'),
    MotivationMessage('Mind, then muscle', 'Set the tone — quick check-in, then the day is yours.'),
    MotivationMessage('Small wins compound', 'Yesterday was data. Today is a chance.'),
    MotivationMessage('Show up for yourself', 'Open FitForge — even a rest day deserves a log.'),
  ];

  static const _workoutReminder = <MotivationMessage>[
    MotivationMessage('Time to lift', 'Your future self thanks you for showing up.'),
    MotivationMessage('Your gym is waiting', 'One more rep than yesterday. That\'s all.'),
    MotivationMessage('Earn it today', 'Pain is temporary. Quitting is forever.'),
    MotivationMessage('Strength is built daily', 'Tap to start your workout.'),
    MotivationMessage('No excuses', 'Even 20 minutes is a win.'),
    MotivationMessage('Push past comfort', 'That\'s where progress lives.'),
    MotivationMessage('Be relentless', 'The bar doesn\'t care how you feel.'),
    MotivationMessage('Consistency wins', 'Every session adds up. Open the app.'),
  ];

  static const _streakSaver = <MotivationMessage>[
    MotivationMessage('Don\'t break the chain', 'Your streak is on the line — quick check-in?'),
    MotivationMessage('Streak alert', 'A short check-in keeps your streak alive.'),
    MotivationMessage('Almost end of day', 'You haven\'t checked in yet. 10 seconds.'),
  ];

  static const _comeback = <MotivationMessage>[
    MotivationMessage('Welcome back', 'No guilt — just the next rep. Let\'s go.'),
    MotivationMessage('Restart now', 'The best time to train was yesterday. Second best is now.'),
    MotivationMessage('Reset, don\'t regret', 'One workout is all it takes to begin again.'),
  ];

  static const _postWorkoutCelebrate = <MotivationMessage>[
    MotivationMessage('Crushed it', 'Great session. Recovery starts now.'),
    MotivationMessage('Logged and locked in', 'Strong work. See you tomorrow.'),
    MotivationMessage('Another brick laid', 'You showed up. That\'s the whole game.'),
  ];

  static MotivationMessage pickMorning({
    required int currentStreak,
    required bool hadRecentWorkout,
  }) {
    if (currentStreak == 0 && !hadRecentWorkout) {
      return _comeback[Random().nextInt(_comeback.length)];
    }
    return _morning[Random().nextInt(_morning.length)];
  }

  static MotivationMessage pickWorkoutReminder({required int currentStreak}) {
    if (currentStreak >= 5) {
      return _streakSaver[Random().nextInt(_streakSaver.length)];
    }
    return _workoutReminder[Random().nextInt(_workoutReminder.length)];
  }

  static MotivationMessage pickPostWorkout() {
    return _postWorkoutCelebrate[
        Random().nextInt(_postWorkoutCelebrate.length)];
  }
}
