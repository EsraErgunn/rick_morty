import 'package:equatable/equatable.dart';

import '../../domain/menu_repository.dart';

enum MenuStatus { initial, success }

final class MenuState extends Equatable {
  const MenuState({this.status = MenuStatus.initial, this.summary});

  final MenuStatus status;
  final MenuSummary? summary;

  @override
  List<Object?> get props => [status, summary];
}
