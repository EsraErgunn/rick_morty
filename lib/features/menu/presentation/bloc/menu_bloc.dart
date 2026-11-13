import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/menu_repository.dart';
import 'menu_event.dart';
import 'menu_state.dart';

/// Ana menü (SPEC §2.2): özeti yükler ve kayıtlı her değişiklikte yeniden
/// yükler. Menü diğer ekranların altında açık kalır, bu yüzden geri dönünce
/// her zaman güncel coin, kart ve deste görünür. Coin değişikliklerinin sesi
/// sayfadaki bir dinleyicinin yan etkisidir.
class MenuBloc extends Bloc<MenuEvent, MenuState> {
  MenuBloc(this._repository) : super(const MenuState()) {
    on<MenuStarted>(_load);
    on<MenuDataChanged>(_load);
    _changes = _repository.changes.listen((_) => add(const MenuDataChanged()));
  }

  final MenuRepository _repository;
  late final StreamSubscription<void> _changes;

  void _load(MenuEvent event, Emitter<MenuState> emit) =>
      emit(MenuState(status: MenuStatus.success, summary: _repository.load()));

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
