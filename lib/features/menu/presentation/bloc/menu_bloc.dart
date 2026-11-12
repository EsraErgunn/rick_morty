import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/menu_repository.dart';
import 'menu_event.dart';
import 'menu_state.dart';

/// Main menu (SPEC §2.2): loads the summary; sound for coin changes is a
/// listener side effect on the page.
class MenuBloc extends Bloc<MenuEvent, MenuState> {
  MenuBloc(this._repository) : super(const MenuState()) {
    on<MenuStarted>(
      (event, emit) => emit(
        MenuState(status: MenuStatus.success, summary: _repository.load()),
      ),
    );
  }

  final MenuRepository _repository;
}
