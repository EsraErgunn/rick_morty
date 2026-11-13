import 'package:equatable/equatable.dart';

import '../../../../core/game/battle_model.dart';

/// Savaş ekranının olaylarının temel sınıfı.
sealed class BattleUiEvent extends Equatable {
  const BattleUiEvent();

  @override
  List<Object?> get props => [];
}

/// Desteyi yükle ve rakibi üret (savaş öncesi ekranı).
final class BattleOpened extends BattleUiEvent {
  const BattleOpened();
}

/// Kayıtlı deste değişti. Yalnızca savaş başlamadan önce uygulanır.
final class BattleDeckChanged extends BattleUiEvent {
  const BattleDeckChanged();
}

/// Savaş öncesi ekranında "Başla".
final class BattleStartPressed extends BattleUiEvent {
  const BattleStartPressed();
}

/// Sahnedeki bir karta dokunuldu: kendi kartı saldıranı seçer, rakip
/// kartına (saldıran seçiliyken) saldırılır.
final class BattleCardTapped extends BattleUiEvent {
  const BattleCardTapped(this.side, this.index);

  final Side side;
  final int index;

  @override
  List<Object?> get props => [side, index];
}

/// Sayfa mevcut tekrar olayının animasyonunu bitirdi.
final class BattleReplayAdvanced extends BattleUiEvent {
  const BattleReplayAdvanced();
}

/// 2× hız anahtarına dokunuldu.
final class BattleSpeedToggled extends BattleUiEvent {
  const BattleSpeedToggled();
}

/// Diyalogda çıkış onaylandı (SPEC §2.7 AC6): yenilgi sayılır.
final class BattleLeft extends BattleUiEvent {
  const BattleLeft();
}
