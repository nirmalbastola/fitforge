/// Pure functions for PR / 1RM calculation. No I/O.
class PrCalculator {
  /// Epley estimated 1RM: w * (1 + r/30).
  /// Returns 0 for invalid inputs.
  static double estimated1RM(double weight, int reps) {
    if (weight <= 0 || reps <= 0) return 0;
    if (reps == 1) return weight;
    return weight * (1 + reps / 30.0);
  }

  /// Volume = weight * reps for a single set.
  static double setVolume(double weight, int reps) {
    if (weight <= 0 || reps <= 0) return 0;
    return weight * reps;
  }
}

enum PrKind { weight, reps, volume, e1rm }

class PrEvent {
  final PrKind kind;
  final double newValue;
  final double previousValue;
  const PrEvent({
    required this.kind,
    required this.newValue,
    required this.previousValue,
  });

  String get label {
    switch (kind) {
      case PrKind.weight:
        return 'Weight PR';
      case PrKind.reps:
        return 'Reps PR';
      case PrKind.volume:
        return 'Volume PR';
      case PrKind.e1rm:
        return 'Strength PR';
    }
  }

  double get delta => newValue - previousValue;
  double get pctImprovement =>
      previousValue == 0 ? 0 : (newValue - previousValue) / previousValue * 100;
}
