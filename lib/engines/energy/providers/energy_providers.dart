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
}

// ── Focus Timer (ephemeral) ──
class FocusTimerNotifier extends Notifier<FocusTimerState> {
  @override
  FocusTimerState build() => const FocusTimerState();

  void start() {
    state = state.copyWith(isRunning: true, startedAt: DateTime.now());
  }

  void pause() => state = state.copyWith(isRunning: false);

  void reset() => state = state.copyWith(
        secondsLeft: state.totalSeconds,
        isRunning: false,
        startedAt: null,
      );

  void tick() {
    if (!state.isRunning) return;
    if (state.secondsLeft <= 1) {
      state = state.copyWith(secondsLeft: 0, isRunning: false);
    } else {
      state = state.copyWith(secondsLeft: state.secondsLeft - 1);
    }
  }

  void setMode(String mode) => state = state.copyWith(
        mode: mode,
        secondsLeft: (mode == 'focus' ? state.focusDuration : state.breakDuration) * 60,
        isRunning: false,
        startedAt: null,
      );

  void setDuration(int focus, int brk) => state = state.copyWith(
        focusDuration: focus,
        breakDuration: brk,
        secondsLeft: (state.mode == 'focus' ? focus : brk) * 60,
      );

  void selectBlock(String label, String category) =>
      state = state.copyWith(selectedBlockLabel: label, selectedBlockCategory: category);

  void setNote(String note) => state = state.copyWith(note: note);
}

final focusTimerProvider =
    NotifierProvider<FocusTimerNotifier, FocusTimerState>(FocusTimerNotifier.new);
