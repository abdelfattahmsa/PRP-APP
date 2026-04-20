import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/energy_models.dart';
import '../data/repositories/energy_repository.dart';

// ── Focus Sessions ──
final focusSessionsProvider =
    AsyncNotifierProvider<FocusSessionsNotifier, List<FocusSession>>(
  FocusSessionsNotifier.new,
);

class FocusSessionsNotifier extends AsyncNotifier<List<FocusSession>> {
  @override
  Future<List<FocusSession>> build() =>
      EnergyRepository.instance.getFocusSessions();

  Future<void> add(FocusSession session) async {
    await EnergyRepository.instance.addFocusSession(session);
    state = AsyncData([session, ...state.value!]);
  }

  Future<void> delete(String id) async {
    await EnergyRepository.instance.deleteFocusSession(id);
    state = AsyncData(state.value!.where((s) => s.id != id).toList());
  }

  Future<void> updateSession(FocusSession session) async {
    await EnergyRepository.instance.updateFocusSession(session);
    state = AsyncData(
        state.value!.map((s) => s.id == session.id ? session : s).toList());
  }
}

// ── Focus Timer (persists across navigation) ──
class FocusTimerNotifier extends Notifier<FocusTimerState> {
  Timer? _timer;

  @override
  FocusTimerState build() {
    ref.onDispose(() => _timer?.cancel());
    return const FocusTimerState();
  }

  void start() {
    _timer?.cancel();
    state = state.copyWith(
      isRunning: true,
      startedAt: DateTime.now(),
      previouslyElapsedSeconds: state.previouslyElapsedSeconds,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!state.isRunning || state.startedAt == null) return;
    final elapsed = DateTime.now().difference(state.startedAt!).inSeconds;
    final totalElapsed = state.previouslyElapsedSeconds + elapsed;
    final left = (state.totalSeconds - totalElapsed).clamp(0, state.totalSeconds);
    if (left <= 0) {
      _timer?.cancel();
      state = state.copyWith(secondsLeft: 0, isRunning: false, completedAt: DateTime.now());
    } else {
      state = state.copyWith(secondsLeft: left);
    }
  }

  void pause() {
    if (!state.isRunning) return;
    _timer?.cancel();
    final elapsed = state.startedAt != null
        ? DateTime.now().difference(state.startedAt!).inSeconds
        : 0;
    state = state.copyWith(
      isRunning: false,
      previouslyElapsedSeconds: state.previouslyElapsedSeconds + elapsed,
      clearStartedAt: true,
    );
  }

  void reset() {
    _timer?.cancel();
    final total = state.totalSeconds;
    state = FocusTimerState(
      mode: state.mode,
      focusDuration: state.focusDuration,
      breakDuration: state.breakDuration,
      selectedBlockLabel: state.selectedBlockLabel,
      selectedBlockCategory: state.selectedBlockCategory,
      secondsLeft: total,
    );
  }

  void setMode(String mode) {
    _timer?.cancel();
    final total = (mode == 'focus' ? state.focusDuration : state.breakDuration) * 60;
    state = FocusTimerState(
      mode: mode,
      focusDuration: state.focusDuration,
      breakDuration: state.breakDuration,
      selectedBlockLabel: state.selectedBlockLabel,
      selectedBlockCategory: state.selectedBlockCategory,
      secondsLeft: total,
    );
  }

  void setDuration(int focus, int brk) {
    _timer?.cancel();
    final total = (state.mode == 'focus' ? focus : brk) * 60;
    state = state.copyWith(
      focusDuration: focus,
      breakDuration: brk,
      secondsLeft: total,
      isRunning: false,
      clearStartedAt: true,
      previouslyElapsedSeconds: 0,
    );
  }

  void selectBlock(String label, String category) =>
      state = state.copyWith(
          selectedBlockLabel: label, selectedBlockCategory: category);

  void setNote(String note) => state = state.copyWith(note: note);
}

final focusTimerProvider =
    NotifierProvider<FocusTimerNotifier, FocusTimerState>(FocusTimerNotifier.new);
