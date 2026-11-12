import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/motion.dart';

import '../../domain/settings_repository.dart';
import 'settings_event.dart';
import 'settings_state.dart';

/// Settings (SPEC §2.9, D2). Applying settings to audio/haptics is a side
/// effect done by the page's listener.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(this._repository) : super(const SettingsState()) {
    on<SettingsStarted>((e, emit) => emit(_load()));
    on<SettingsChanged>((e, emit) async {
      emit(state.copyWith(settings: e.settings));
      final r = await _repository.saveSettings(e.settings);
      r.match((f) => emit(state.copyWith(failure: f)), (_) {});
    });
    on<VersionTapped>(_onVersionTapped);
    on<DemoCoinsRequested>((e, emit) async {
      final r = await _repository.addDemoCoins();
      emit(
        r.match(
          (f) => state.copyWith(failure: f),
          (coins) => state.copyWith(coins: coins),
        ),
      );
    });
    on<DemoLegendaryRequested>((e, emit) async {
      final r = await _repository.armLegendary();
      emit(
        r.match(
          (f) => state.copyWith(failure: f),
          (_) => state.copyWith(legendaryArmed: true),
        ),
      );
    });
    on<DemoClosed>((e, emit) async {
      await _repository.setDemoUnlocked(false);
      _taps.clear();
      emit(state.copyWith(demoUnlocked: false));
    });
    on<ProgressResetConfirmed>((e, emit) async {
      final r = await _repository.resetProgress();
      r.match(
        (f) => emit(state.copyWith(failure: f)),
        (_) => emit(_load().copyWith(resetTick: state.resetTick + 1)),
      );
    });
  }

  final SettingsRepository _repository;
  final List<DateTime> _taps = [];

  static const int tapsToUnlock = 7;
  static const Duration tapWindow = AppMotion.demoTapWindow;

  SettingsState _load() => state.copyWith(
    status: SettingsStatus.success,
    settings: _repository.settings,
    demoUnlocked: _repository.demoUnlocked,
    legendaryArmed: _repository.legendaryArmed,
    coins: _repository.coins,
  );

  Future<void> _onVersionTapped(
    VersionTapped e,
    Emitter<SettingsState> emit,
  ) async {
    if (state.demoUnlocked) return;
    _taps
      ..add(e.at)
      ..removeWhere((t) => e.at.difference(t) > tapWindow);
    if (_taps.length < tapsToUnlock) return;
    _taps.clear();
    await _repository.setDemoUnlocked(true);
    emit(
      state.copyWith(
        demoUnlocked: true,
        demoUnlockedTick: state.demoUnlockedTick + 1,
      ),
    );
  }
}
