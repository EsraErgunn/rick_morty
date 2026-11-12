import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:portalcards/core/audio/audio_assets.dart';
import 'package:portalcards/core/audio/audio_service.dart';
import 'package:portalcards/core/cards/game_card_data.dart';
import 'package:portalcards/core/errors/failures.dart';
import 'package:portalcards/core/feedback/ui_feedback.dart';
import 'package:portalcards/core/game/card_type.dart';
import 'package:portalcards/core/game/rarity.dart';
import 'package:portalcards/core/haptics/haptics_service.dart';
import 'package:portalcards/core/sensors/tilt_stream.dart';
import 'package:portalcards/core/storage/api_data_store.dart';
import 'package:portalcards/core/storage/player_store.dart';
import 'package:portalcards/core/widgets/game_card/card_art.dart';
import 'package:portalcards/core/widgets/game_card/flip_card.dart';
import 'package:portalcards/core/widgets/shader_cache.dart';
import 'package:portalcards/features/collection/data/collection_repository_impl.dart';
import 'package:portalcards/features/collection/domain/collection_repository.dart';
import 'package:portalcards/features/collection/presentation/bloc/card_detail_bloc.dart';
import 'package:portalcards/features/collection/presentation/bloc/card_detail_event.dart';
import 'package:portalcards/features/collection/presentation/bloc/collection_bloc.dart';
import 'package:portalcards/features/collection/presentation/bloc/collection_event.dart';
import 'package:portalcards/features/collection/presentation/bloc/collection_state.dart';
import 'package:portalcards/features/collection/presentation/pages/card_detail_page.dart';
import 'package:portalcards/features/collection/presentation/pages/collection_page.dart';
import 'package:portalcards/features/sync/data/mappers.dart';

import '../../core/storage/hive_test_helper.dart';
import '../../fixtures/fixtures.dart';
import '../../helpers/cards.dart';
import '../../helpers/fake_audio.dart';

final _t0 = DateTime.utc(2026, 11, 12);

/// In-memory repository for widget tests (Hive file I/O does not run
/// inside the widget tester's fake async zone).
class _MemoryRepo implements CollectionRepository {
  _MemoryRepo({List<int> owned = const [], List<int> deck = const []})
    : _owned = [...owned],
      _deck = [...deck];

  final List<int> _owned;
  List<int> _deck;

  @override
  List<CollectionEntry> entries() => [
    for (final (i, id) in _owned.indexed)
      CollectionEntry(
        card: fixtureCard(id),
        copies: 1,
        obtainedAt: _t0.add(Duration(minutes: i)),
      ),
  ];

  @override
  int get totalCharacters => characterFixtures.length;

  @override
  GameCardData? card(int id) =>
      characterFixtures.containsKey(id) ? fixtureCard(id) : null;

  @override
  bool owns(int id) => _owned.contains(id);

  @override
  List<int> get deck => List.unmodifiable(_deck);

  @override
  Future<Either<Failure, List<int>>> toggleDeck(int id) async {
    if (_deck.contains(id)) {
      _deck = [..._deck]..remove(id);
    } else if (_deck.length >= CollectionRepository.deckSize) {
      return left(const DeckFullFailure());
    } else {
      _deck = [..._deck, id];
    }
    return right(deck);
  }
}

void main() {
  useTempHive();

  late PlayerStore player;
  late CollectionStore collection;
  late CollectionRepositoryImpl repo;
  late FakeBackend audioBackend;
  late UiFeedback feedback;

  setUp(() async {
    final api = await ApiDataStore.open();
    await api.putCharacters([
      for (final id in characterFixtures.keys)
        parseCharacter(loadCharacter(id))
            .getOrElse((f) => throw StateError('$f')),
    ]);
    player = await PlayerStore.open();
    collection = await CollectionStore.open();
    repo = CollectionRepositoryImpl(
      apiData: api,
      player: player,
      collection: collection,
    );
    audioBackend = FakeBackend();
    final audio = AudioService(backend: audioBackend);
    feedback = UiFeedback(
      audio: audio,
      haptics: HapticsService(driver: (_) async {}),
    );
    CardArt.debugArtBuilder = testArt;
  });
  tearDown(() => CardArt.debugArtBuilder = null);

  Future<void> own(List<int> ids) async {
    for (final (i, id) in ids.indexed) {
      await collection.addCopy(id, _t0.add(Duration(minutes: i)));
    }
  }

  group('repository: deck', () {
    test('add, add, add, then full; remove frees a slot', () async {
      await own([1, 2, 23, 71]);
      expect((await repo.toggleDeck(1)).isRight(), isTrue);
      expect((await repo.toggleDeck(2)).isRight(), isTrue);
      expect((await repo.toggleDeck(23)).isRight(), isTrue);
      expect(
        (await repo.toggleDeck(71)).getLeft().toNullable(),
        const DeckFullFailure(),
      );
      expect(player.state.deck, [1, 2, 23]);

      await repo.toggleDeck(2);
      expect(player.state.deck, [1, 23]);
    });

    test('a card you do not own cannot join the deck', () async {
      expect((await repo.toggleDeck(1)).isLeft(), isTrue);
      expect(player.state.deck, isEmpty);
    });
  });

  group('bloc: filters and sort', () {
    blocTest<CollectionBloc, CollectionState>(
      'default sort: legendary first; filters narrow the grid',
      setUp: () => own([71, 1, 23, 86, 309]),
      build: () => CollectionBloc(repo),
      act: (b) => b
        ..add(const CollectionStarted())
        ..add(const CollectionRarityToggled(Rarity.rare))
        ..add(const CollectionTypeToggled(CardType.human)),
      verify: (b) {
        expect(b.state.total, characterFixtures.length);
        expect(b.state.entries, hasLength(5));
        expect(b.state.visible.map((e) => e.card.id), [86]);
      },
    );

    blocTest<CollectionBloc, CollectionState>(
      'sort by rarity, name and newest',
      setUp: () => own([71, 1, 23]),
      build: () => CollectionBloc(repo),
      act: (b) => b.add(const CollectionStarted()),
      verify: (b) {
        final s = b.state;
        expect(s.visible.map((e) => e.card.id), [1, 23, 71]);
        expect(
          s.copyWith(sort: CollectionSort.name).visible.map((e) => e.card.id),
          [23, 71, 1], // Arcade Alien, Conroy, Rick Sanchez
        );
        expect(
          s.copyWith(sort: CollectionSort.newest).visible.map((e) => e.card.id),
          [23, 1, 71],
        );
      },
    );

    blocTest<CollectionBloc, CollectionState>(
      '"Hepsi" clears the filters',
      setUp: () => own([71, 1]),
      build: () => CollectionBloc(repo),
      act: (b) => b
        ..add(const CollectionStarted())
        ..add(const CollectionRarityToggled(Rarity.epic))
        ..add(const CollectionFiltersCleared()),
      verify: (b) => expect(b.state.visible, hasLength(2)),
    );
  });

  group('collection page', () {
    late List<int> opened;
    late int portal;

    Future<void> pumpPage(
      WidgetTester tester, [
      List<int> owned = const [],
    ]) async {
      final memory = _MemoryRepo(owned: owned);
      opened = [];
      portal = 0;
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        testApp(
          BlocProvider(
            create: (_) =>
                CollectionBloc(memory)..add(const CollectionStarted()),
            child: CollectionPage(
              feedback: feedback,
              onOpenCard: opened.add,
              onOpenPortal: () => portal++,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('empty: message + button to the portal', (tester) async {
      await pumpPage(tester);
      expect(find.text('Henüz kartın yok. İlk portalını aç.'), findsOneWidget);
      await tester.tap(find.text('Portalı aç'));
      expect(portal, 1);
    });

    testWidgets('header count, filter chip, open a card with flip sound', (
      tester,
    ) async {
      await pumpPage(tester, [71, 1, 23]);
      expect(find.text('3/8'), findsOneWidget);
      expect(find.byKey(const ValueKey('grid-1')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('filter-epic')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('filter-epic')));
      await frames(tester, const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('grid-1')), findsNothing);
      expect(find.byKey(const ValueKey('grid-23')), findsOneWidget);
      expect(audioBackend.sfx.map((e) => e.$1), contains(Sfx.buttonTap));

      await tester.tap(find.byKey(const ValueKey('grid-23')));
      expect(opened, [23]);
      expect(audioBackend.sfx.map((e) => e.$1), contains(Sfx.cardFlip));
    });

    testWidgets('a filter with no match shows a message', (tester) async {
      await pumpPage(tester, [71]);
      await tester.ensureVisible(
        find.byKey(const ValueKey('filter-legendary')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('filter-legendary')));
      await frames(tester, const Duration(milliseconds: 400));
      expect(find.text('Bu filtreye uyan kart yok.'), findsOneWidget);
    });
  });

  group('card detail page', () {
    final shaders = ShaderCache(loader: (_) => Future.error(StateError('x')));
    setUpAll(shaders.load);

    late _MemoryRepo memory;

    Future<void> pumpDetail(
      WidgetTester tester,
      int id, {
      List<int> owned = const [],
      List<int> deck = const [],
    }) async {
      memory = _MemoryRepo(owned: owned, deck: deck);
      final tilt = TiltStream(source: () => const Stream.empty());
      addTearDown(tilt.dispose);
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        testApp(
          BlocProvider(
            create: (_) =>
                CardDetailBloc(memory, id)..add(const CardDetailStarted()),
            child: CardDetailPage(
              id: id,
              tiltStream: tilt,
              shaders: shaders,
              feedback: feedback,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('owned card: add to deck, then remove', (tester) async {
      await pumpDetail(tester, 1, owned: [1]);
      expect(find.text('Deste 0/3'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('deck-add')));
      await frames(tester, const Duration(milliseconds: 400));
      expect(find.text('Deste 1/3'), findsOneWidget);
      expect(find.byKey(const ValueKey('deck-remove')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('deck-remove')));
      await frames(tester, const Duration(milliseconds: 400));
      expect(memory.deck, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('full deck: add is disabled with the reason', (tester) async {
      await pumpDetail(tester, 1, owned: [1, 2, 23, 71], deck: [2, 23, 71]);
      final add = tester.widget<FilledButton>(
        find.byKey(const ValueKey('deck-add')),
      );
      expect(add.onPressed, isNull);
      expect(find.text('Deste dolu (3/3)'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a card you do not own shows no deck action', (tester) async {
      await pumpDetail(tester, 2);
      expect(find.text('Morty Smith'), findsWidgets);
      expect(find.text('Bu karta henüz sahip değilsin.'), findsOneWidget);
      expect(find.byKey(const ValueKey('deck-add')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('tap flips the card with the flip sound', (tester) async {
      await pumpDetail(tester, 23, owned: [23]);
      await tester.tap(find.byType(FlipCard));
      await frames(tester, const Duration(milliseconds: 500));
      expect(audioBackend.sfx.map((e) => e.$1), contains(Sfx.cardFlip));
      expect(find.text('Köken'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
