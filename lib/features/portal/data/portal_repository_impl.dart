import 'dart:math';

import 'package:fpdart/fpdart.dart';

import '../../../core/cards/card_factory.dart';
import '../../../core/cards/rarity_pool.dart';
import '../../../core/errors/failures.dart';
import '../../../core/game/economy.dart';
import '../../../core/game/portal_roll.dart';
import '../../../core/game/rarity.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/storage/api_data_store.dart';
import '../../../core/storage/player_store.dart';
import '../domain/portal_repository.dart';

/// Yazım sırası (SPEC §2.3 AC8): tüm kontroller ve çekiliş önce yapılır,
/// sonra (1) koleksiyon kartı alır, (2) tek bir `PlayerStore.update`
/// coin'leri, `portalsOpened` değerini, demo işaretini ve sallama ipucunu kaydeder. Uygulama
/// (1) ile (2) arasında kapanırsa oyuncu bedava bir kart kazanır; kartsız
/// asla coin kaybetmez.
class PortalRepositoryImpl implements PortalRepository {
  PortalRepositoryImpl({
    required this._apiData,
    required this._player,
    required this._collection,
    required this._pool,
    required this._random,
    this._clock = DateTime.now,
  });

  final ApiDataStore _apiData;
  final PlayerStore _player;
  final CollectionStore _collection;
  final RarityPool _pool;
  final Random _random;
  final DateTime Function() _clock;

  @override
  int get coins => _player.state.coins;

  @override
  bool get shakeHintSeen => _player.state.shakeHintSeen;

  @override
  Future<Either<Failure, PortalResult>> open() async {
    final state = _player.state;
    final spend = Economy.spend(
      state.coins,
      EconomyRules.portalCost,
      CoinReason.portal,
    );
    if (spend == null) {
      return left(NotEnoughCoinsFailure(EconomyRules.portalCost, state.coins));
    }

    final pick = PortalRoll.pick(
      pool: {for (final r in Rarity.values) r: _pool.ids(r)},
      owned: _collection.ownedIds,
      portalsOpened: state.portalsOpened,
      forceLegendary: state.forceNextLegendary,
      random: _random,
    );
    final character = _apiData.character(pick.characterId);
    if (character == null) {
      return left(StorageFailure('character ${pick.characterId} missing'));
    }
    final card = CardFactory.fromCharacter(character);
    final refund = pick.isDuplicate
        ? Economy.earn(
            spend.after,
            Economy.duplicateCoins(card.rarity),
            CoinReason.duplicate,
          )
        : null;
    final coinsAfter = refund?.after ?? spend.after;

    try {
      await _collection.addCopy(card.id, _clock());
      await _player.update(
        (s) => s.copyWith(
          coins: coinsAfter,
          portalsOpened: s.portalsOpened + 1,
          forceNextLegendary: false,
          shakeHintSeen: true,
        ),
      );
    } on Object catch (e, st) {
      AppLogger.error('portal save failed', e, st);
      return left(StorageFailure(e.runtimeType.toString()));
    }

    AppLogger.info('$spend');
    if (refund != null) AppLogger.info('$refund');
    AppLogger.info('portal: $pick');

    return right(
      PortalResult(
        card: card,
        rolled: pick.rolled,
        isDuplicate: pick.isDuplicate,
        duplicateCoins: refund?.delta ?? 0,
        coinsBefore: spend.before,
        coinsAfter: coinsAfter,
      ),
    );
  }
}
