import '../../data/db/app_database.dart';

class ProgressionSuggestion {
  final double suggestedWeight;
  final int suggestedRepsMin;
  final int suggestedRepsMax;
  final String reasoning;
  const ProgressionSuggestion({
    required this.suggestedWeight,
    required this.suggestedRepsMin,
    required this.suggestedRepsMax,
    required this.reasoning,
  });
}

/// Double-progression model:
///  • If last performance hit the top of the rep range across all sets → bump weight, drop to rep-range minimum.
///  • If hit somewhere inside the range → keep weight, push for one more rep.
///  • If failed bottom of range → keep weight, stay in range.
///  • If no history → use plan target as starting point.
class ProgressionEngine {
  final double weightStep;
  const ProgressionEngine({this.weightStep = 2.5});

  ProgressionSuggestion suggest({
    required List<WorkoutSet> previousDoneSets,
    int targetRepsMin = 8,
    int targetRepsMax = 12,
    int targetSets = 3,
  }) {
    if (previousDoneSets.isEmpty) {
      return ProgressionSuggestion(
        suggestedWeight: 0,
        suggestedRepsMin: targetRepsMin,
        suggestedRepsMax: targetRepsMax,
        reasoning: 'First time — start light and find your working weight.',
      );
    }

    final lastWeight = previousDoneSets
        .map((s) => s.weight)
        .reduce((a, b) => a > b ? a : b);
    final topSets =
        previousDoneSets.where((s) => s.weight == lastWeight).toList();

    final allHitTop =
        topSets.every((s) => s.reps >= targetRepsMax) && topSets.length >= targetSets;
    if (allHitTop) {
      return ProgressionSuggestion(
        suggestedWeight: lastWeight + weightStep,
        suggestedRepsMin: targetRepsMin,
        suggestedRepsMax: targetRepsMax,
        reasoning:
            'Hit $targetRepsMax+ on all sets at ${_fmt(lastWeight)}. Bump to ${_fmt(lastWeight + weightStep)}.',
      );
    }

    final bestReps =
        topSets.map((s) => s.reps).reduce((a, b) => a > b ? a : b);
    if (bestReps >= targetRepsMin) {
      return ProgressionSuggestion(
        suggestedWeight: lastWeight,
        suggestedRepsMin: bestReps + 1 > targetRepsMax
            ? targetRepsMin
            : (bestReps + 1).clamp(targetRepsMin, targetRepsMax),
        suggestedRepsMax: targetRepsMax,
        reasoning:
            'Last: ${_fmt(lastWeight)} × $bestReps. Push for ${bestReps + 1} this session.',
      );
    }

    return ProgressionSuggestion(
      suggestedWeight: lastWeight,
      suggestedRepsMin: targetRepsMin,
      suggestedRepsMax: targetRepsMax,
      reasoning:
          'Stay at ${_fmt(lastWeight)} until you hit $targetRepsMin clean reps.',
    );
  }

  static String _fmt(double w) {
    if (w == w.truncateToDouble()) return '${w.toStringAsFixed(0)}kg';
    return '${w.toStringAsFixed(1)}kg';
  }
}
