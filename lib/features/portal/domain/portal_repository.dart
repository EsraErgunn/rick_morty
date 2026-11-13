import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/cards/game_card_data.dart';
import '../../../core/errors/failures.dart';
import '../../../core/game/rarity.dart';

/// Tek bir portalın verdiği. Çağırana ulaştığında zaten kaydedilmiştir
/// (animasyondan önce yaz, SPEC §2.3 AC8).
final class PortalResult extends Equatable {
  const PortalResult({
    required this.card,
    required this.rolled,
    required this.isDuplicate,
    required this.duplicateCoins,
    required this.coinsBefore,
    required this.coinsAfter,
  });

  final GameCardData card;

  /// Çekilişten gelen nadirlik; aşağı kayma sonrası `card.rarity`'den farklıdır.
  final Rarity rolled;
  final bool isDuplicate;

  /// Tekrar gelen kart için geri ödenen coin (yeni kart için 0).
  final int duplicateCoins;
  final int coinsBefore;
  final int coinsAfter;

  bool get isLegendary => card.rarity == Rarity.legendary;

  @override
  List<Object?> get props => [
    card,
    rolled,
    isDuplicate,
    duplicateCoins,
    coinsBefore,
    coinsAfter,
  ];
}

/// Portal ekranının veri kaynağı: coin, ipucu ve portal açma.
abstract interface class PortalRepository {
  /// Mevcut coin'ler (sayaç ve "yetersiz coin" kontrolü için).
  int get coins;

  /// İlk portal açılana kadar false (sallama ipucu, SPEC D4).
  bool get shakeHintSeen;

  /// Portal ücretini harcar, çekiliş yapar, kartı (ya da tekrar
  /// coin'lerini) ve oyuncu durumunu kaydeder, sonra sonucu döndürür.
  /// [NotEnoughCoinsFailure] hiçbir şeyi değiştirmez.
  Future<Either<Failure, PortalResult>> open();
}
