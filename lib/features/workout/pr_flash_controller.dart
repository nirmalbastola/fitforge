import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logic/pr_calculator.dart';

class PrFlashController extends Notifier<List<PrEvent>> {
  Timer? _clear;

  @override
  List<PrEvent> build() {
    ref.onDispose(() => _clear?.cancel());
    return const [];
  }

  void show(List<PrEvent> events) {
    if (events.isEmpty) return;
    _clear?.cancel();
    state = events;
    _clear = Timer(const Duration(seconds: 3), () => state = const []);
  }

  void dismiss() {
    _clear?.cancel();
    state = const [];
  }
}

final prFlashProvider =
    NotifierProvider<PrFlashController, List<PrEvent>>(PrFlashController.new);
