import 'package:equatable/equatable.dart';

import '../../domain/menu_repository.dart';

/// Menü özetinin yüklenme durumu.
enum MenuStatus { initial, success }

/// Ana menünün durumu: yükleme durumu ve menü özeti (coin, kartlar, deste).
final class MenuState extends Equatable {
  const MenuState({this.status = MenuStatus.initial, this.summary});

  final MenuStatus status;
  final MenuSummary? summary;

  @override
  List<Object?> get props => [status, summary];
}
