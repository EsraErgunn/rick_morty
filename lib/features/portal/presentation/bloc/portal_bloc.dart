import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/portal_repository.dart';
import 'portal_event.dart';
import 'portal_state.dart';

/// Portal ekranı akışı (SPEC §2.3). Sonuç, durum `revealing` olmadan önce
/// repository tarafından kaydedilir, böylece animasyon asla kart kaybettiremez
/// ya da coin iade ettiremez (AC8). Sesler ve titreşimler durum değişikliklerinin
/// ve sahne vuruşlarının yan etkileridir, sayfanın dinleyicileri tarafından işlenir.
class PortalBloc extends Bloc<PortalEvent, PortalState> {
  PortalBloc(this._repository) : super(const PortalState()) {
    on<PortalStarted>(_onStarted);
    on<PortalShaken>(_onOpen);
    on<PortalOpenRequested>(_onOpen);
    on<RevealFinished>(_onRevealFinished);
    on<PortalReset>(_onReset);
  }

  final PortalRepository _repository;

  void _onStarted(PortalStarted event, Emitter<PortalState> emit) => emit(
    state.copyWith(
      coins: _repository.coins,
      showShakeHint: !_repository.shakeHintSeen,
    ),
  );

  Future<void> _onOpen(PortalEvent event, Emitter<PortalState> emit) async {
    if (state.busy) return;
    emit(state.copyWith(phase: PortalPhase.opening, clearFailure: true));

    final result = await _repository.open();
    result.match(
      (failure) => emit(
        failure is NotEnoughCoinsFailure
            ? state.copyWith(
                phase: PortalPhase.idle,
                coins: failure.balance,
                notEnoughCoins: state.notEnoughCoins + 1,
              )
            : state.copyWith(phase: PortalPhase.idle, failure: failure),
      ),
      (r) => emit(
        state.copyWith(
          phase: PortalPhase.revealing,
          result: r,
          coins: r.coinsAfter,
          showShakeHint: false,
        ),
      ),
    );
  }

  void _onRevealFinished(RevealFinished event, Emitter<PortalState> emit) {
    if (state.phase != PortalPhase.revealing) return;
    emit(state.copyWith(phase: PortalPhase.revealed));
  }

  void _onReset(PortalReset event, Emitter<PortalState> emit) => emit(
    state.copyWith(
      phase: PortalPhase.idle,
      coins: _repository.coins,
      clearResult: true,
    ),
  );
}
