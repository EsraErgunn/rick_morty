import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/menu_repository.dart';
import 'menu_event.dart';
import 'menu_state.dart';

/// Main menu (SPEC §2.2): loads the summary and reloads it on every stored
/// change. The menu stays mounted under the other screens, so going back
/// always shows the current coins, cards and deck. Sound for coin changes
/// is a listener side effect on the page.
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
