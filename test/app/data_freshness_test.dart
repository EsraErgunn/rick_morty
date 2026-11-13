import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/core/cards/rarity_pool.dart';
import 'package:portalcards/core/entities/character.dart';
import 'package:portalcards/core/game/battle_model.dart';
import 'package:portalcards/core/storage/api_data_store.dart';
import 'package:portalcards/core/storage/player_store.dart';
import 'package:portalcards/features/battle/data/battle_repository_impl.dart';
import 'package:portalcards/features/battle/presentation/bloc/battle_bloc.dart';
import 'package:portalcards/features/battle/presentation/bloc/battle_event.dart';
import 'package:portalcards/features/battle/presentation/bloc/battle_state.dart';
import 'package:portalcards/features/collection/data/collection_repository_impl.dart';
import 'package:portalcards/features/collection/presentation/bloc/collection_bloc.dart';
import 'package:portalcards/features/collection/presentation/bloc/collection_event.dart';
import 'package:portalcards/features/deck/presentation/bloc/deck_bloc.dart';
import 'package:portalcards/features/deck/presentation/bloc/deck_event.dart';
import 'package:portalcards/features/menu/data/menu_repository_impl.dart';
import 'package:portalcards/features/menu/presentation/bloc/menu_bloc.dart';
import 'package:portalcards/features/menu/presentation/bloc/menu_event.dart';
import 'package:portalcards/features/portal/data/portal_repository_impl.dart';
import 'package:portalcards/features/settings/data/settings_repository_impl.dart';
import 'package:portalcards/features/sync/data/mappers.dart';

import '../core/storage/hive_test_helper.dart';
import '../fixtures/fixtures.dart';

/// Menü diğer her ekranın altında açık kalır (onlar onun alt
/// rotalarıdır), bu yüzden depoları bir kez okuyan bir bloc geri dönünce eski veri
/// gösterir. Aşağıdaki her bloc önce açılır, sonra veri başka bir yerde
/// değişir; telefonda olduğu gibi.
void main() {
  useTempHive();

  late ApiDataStore apiData;
  late PlayerStore player;
  late CollectionStore collection;
  late RarityPool pool;
  late List<Character> characters;

  setUp(() async {
    apiData = await ApiDataStore.open();
    characters = [
      for (final id in characterFixtures.keys)
        parseCharacter(loadCharacter(id))
            .getOrElse((f) => throw StateError('$f')),
    ];
    await apiData.putCharacters(characters);
    player = await PlayerStore.open();
    collection = await CollectionStore.open();
    pool = RarityPool.fromCharacters(characters);
  });

  MenuBloc menu() => MenuBloc(
    MenuRepositoryImpl(
      apiData: apiData,
      player: player,
      collection: collection,
    ),
  )..add(const MenuStarted());

  CollectionRepositoryImpl cards() => CollectionRepositoryImpl(
    apiData: apiData,
    player: player,
    collection: collection,
  );

  BattleRepositoryImpl battles() =>
      BattleRepositoryImpl(apiData: apiData, player: player, pool: pool);

  PortalRepositoryImpl portal() => PortalRepositoryImpl(
    apiData: apiData,
    player: player,
    collection: collection,
    pool: pool,
    random: Random(1),
  );

  Future<void> settle() => pumpEventQueue();

  Future<void> own(Iterable<int> ids) async {
    for (final id in ids) {
      await collection.addCopy(id, DateTime.utc(2026, 11, 13));
    }
  }

  test('portal spends coins → the open menu shows the new balance', () async {
    final m = menu();
    await settle();
    expect(m.state.summary!.coins, 300);

    final result = await portal().open();
    await settle();

    expect(result.isRight(), isTrue);
    expect(m.state.summary!.coins, 200);
    await m.close();
  });

  test(
    'portal card → the open menu counts it and the open deck lists it',
    () async {
      final m = menu();
      final deck = DeckBloc(cards())..add(const DeckStarted());
      final grid = CollectionBloc(cards())..add(const CollectionStarted());
      await settle();
      expect(m.state.summary!.owned, 0);
      expect(deck.state.owned, isEmpty);

      final won = (await portal().open()).getOrElse(
        (f) => throw StateError('$f'),
      );
      await settle();

      expect(m.state.summary!.owned, 1);
      expect(deck.state.owned.map((c) => c.id), [won.card.id]);
      expect(grid.state.entries.map((e) => e.card.id), [won.card.id]);
      await Future.wait([m.close(), deck.close(), grid.close()]);
    },
  );

  test(
    'deck change → the open menu and pre-battle show the new deck',
    () async {
      final ids = characters.take(3).map((c) => c.id).toList();
      await own(ids);
      final m = menu();
      final battle = BattleBloc(
        repository: battles(),
        random: Random(1),
        newBattleId: () => 'b1',
      )..add(const BattleOpened());
      final deck = DeckBloc(cards())..add(const DeckStarted());
      await settle();
      expect(battle.state.phase, BattlePhase.noDeck);

      for (final id in ids) {
        deck.add(DeckCardTapped(id));
        await settle();
      }

      expect(m.state.summary!.deckSize, 3);
      expect(battle.state.phase, BattlePhase.preBattle);
      expect(battle.state.playerCards.map((c) => c.id), ids);
      await Future.wait([m.close(), battle.close(), deck.close()]);
    },
  );

  test('pre-battle keeps its opponent when the deck changes', () async {
    final ids = characters.take(4).map((c) => c.id).toList();
    await own(ids);
    await player.update((s) => s.copyWith(deck: ids.take(3).toList()));
    final battle = BattleBloc(
      repository: battles(),
      random: Random(1),
      newBattleId: () => 'b1',
    )..add(const BattleOpened());
    await settle();
    final enemy = battle.state.enemyCards;

    await player.update((s) => s.copyWith(deck: [ids[3], ids[1], ids[2]]));
    await settle();

    expect(battle.state.playerCards.first.id, ids[3]);
    expect(battle.state.enemyCards, enemy);
    await battle.close();
  });

  test('battle reward → the open menu shows the new balance', () async {
    final m = menu();
    await settle();

    await battles().finish('b1', BattleResult.victory);
    await settle();

    expect(m.state.summary!.coins, 400);
    await m.close();
  });

  test('settings demo coins → the open menu shows the new balance', () async {
    final m = menu();
    await settle();

    await SettingsRepositoryImpl(
      player: player,
      collection: collection,
    ).addDemoCoins();
    await settle();

    expect(m.state.summary!.coins, 1300);
    await m.close();
  });
}
