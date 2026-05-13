import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestTimerState {
  final bool active;
  final int totalSeconds;
  final int remainingSeconds;

  const RestTimerState({
    required this.active,
    required this.totalSeconds,
    required this.remainingSeconds,
  });

  static const idle = RestTimerState(
      active: false, totalSeconds: 0, remainingSeconds: 0);
}

class RestTimerController extends Notifier<RestTimerState> {
  Timer? _ticker;

  @override
  RestTimerState build() {
    ref.onDispose(() => _ticker?.cancel());
    return RestTimerState.idle;
  }

  void start(int seconds) {
    _ticker?.cancel();
    state = RestTimerState(
      active: true,
      totalSeconds: seconds,
      remainingSeconds: seconds,
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      final next = state.remainingSeconds - 1;
      if (next <= 0) {
        t.cancel();
        HapticFeedback.heavyImpact();
        state = RestTimerState.idle;
      } else {
        state = RestTimerState(
          active: true,
          totalSeconds: state.totalSeconds,
          remainingSeconds: next,
        );
      }
    });
  }

  void addSeconds(int delta) {
    if (!state.active) return;
    final next = (state.remainingSeconds + delta).clamp(0, 9999);
    if (next == 0) {
      _ticker?.cancel();
      state = RestTimerState.idle;
    } else {
      state = RestTimerState(
        active: true,
        totalSeconds: state.totalSeconds + delta.clamp(0, delta),
        remainingSeconds: next,
      );
    }
  }

  void cancel() {
    _ticker?.cancel();
    state = RestTimerState.idle;
  }
}

final restTimerProvider =
    NotifierProvider<RestTimerController, RestTimerState>(
        RestTimerController.new);
