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
import 'package:portalcards/core/haptics/haptics_service.dart';
import 'package:portalcards/core/widgets/game_card/card_art.dart';
import 'package:portalcards/features/collection/domain/collection_repository.dart';
import 'package:portalcards/features/deck/presentation/bloc/deck_bloc.dart';
import 'package:portalcards/features/deck/presentation/bloc/deck_event.dart';
import 'package:portalcards/features/deck/presentation/bloc/deck_state.dart';
import 'package:portalcards/features/deck/presentation/pages/deck_page.dart';

import '../../fixtures/fixtures.dart';
import '../../helpers/cards.dart';
import '../../helpers/fake_audio.dart';

final _t0 = DateTime.utc(2026, 11, 12);

class _MemoryRepo implements CollectionRepository {
  @override
  Stream<void> get changes => const Stream.empty();

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
  group('DeckBloc', () {
    blocTest<DeckBloc, DeckState>(
      'tapping three cards fills the deck and completes it',
      build: () => DeckBloc(_MemoryRepo(owned: [1, 2, 23, 71])),
      act: (b) => b
        ..add(const DeckStarted())
        ..add(const DeckCardTapped(1))
        ..add(const DeckCardTapped(2))
        ..add(const DeckCardTapped(23)),
      skip: 1,
      expect: () => [
        isA<DeckState>()
            .having((s) => s.deck, 'deck', [1])
            .having((s) => s.change, 'change', DeckChange.added),
        isA<DeckState>().having((s) => s.deck, 'deck', [1, 2]),
        isA<DeckState>()
            .having((s) => s.deck, 'deck', [1, 2, 23])
            .having((s) => s.change, 'change', DeckChange.completed),
      ],
    );

    blocTest<DeckBloc, DeckState>(
      'a duplicate or a fourth card is ignored',
      build: () =>
          DeckBloc(_MemoryRepo(owned: [1, 2, 23, 71], deck: [1, 2, 23])),
      act: (b) => b
        ..add(const DeckStarted())
        ..add(const DeckCardTapped(1))
        ..add(const DeckCardTapped(71)),
      skip: 1,
      expect: () => <DeckState>[],
    );

    blocTest<DeckBloc, DeckState>(
      'tapping a filled slot empties it; an empty slot does nothing',
      build: () => DeckBloc(_MemoryRepo(owned: [1, 2, 23], deck: [1, 2])),
      act: (b) => b
        ..add(const DeckStarted())
        ..add(const DeckSlotTapped(2))
        ..add(const DeckSlotTapped(0)),
      skip: 1,
      expect: () => [
        isA<DeckState>()
            .having((s) => s.deck, 'deck', [2])
            .having((s) => s.change, 'change', DeckChange.removed),
      ],
    );

    test('totals and type coverage come from the deck cards', () {
      final state = DeckState(
        status: DeckStatus.success,
        owned: [fixtureCard(1), fixtureCard(23), fixtureCard(71)],
        deck: const [1, 23],
      );
      final rick = fixtureCard(1).stats;
      final alien = fixtureCard(23).stats;
      expect(state.totalHp, rick.hp + alien.hp);
      expect(state.totalAtk, rick.atk + alien.atk);
      expect(state.coverage, {CardType.human, CardType.alien});
    });
  });

  group('DeckPage', () {
    late FakeBackend backend;
    late UiFeedback feedback;

    setUp(() {
      backend = FakeBackend();
      feedback = UiFeedback(
        audio: AudioService(backend: backend),
        haptics: HapticsService(driver: (_) async {}),
      );
      CardArt.debugArtBuilder = testArt;
    });
    tearDown(() => CardArt.debugArtBuilder = null);

    Future<DeckBloc> pump(WidgetTester tester, _MemoryRepo repo) async {
      tester.view
        ..physicalSize = const Size(1080, 2340)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final bloc = DeckBloc(repo)..add(const DeckStarted());
      await tester.pumpWidget(
        testApp(
          BlocProvider.value(
            value: bloc,
            child: DeckPage(feedback: feedback),
          ),
        ),
      );
      await frames(tester, const Duration(milliseconds: 100));
      return bloc;
    }

    testWidgets('empty collection shows the hint to open a portal', (
      tester,
    ) async {
      await pump(tester, _MemoryRepo());
      expect(find.text('Henüz kartın yok. Önce portal aç.'), findsOneWidget);
    });

    testWidgets('tap card → slot fills with sound; complete → success sound', (
      tester,
    ) async {
      final repo = _MemoryRepo(owned: [1, 2, 23, 71]);
      await pump(tester, repo);
      expect(find.text('Boş'), findsNWidgets(3));

      for (final id in [1, 2, 23]) {
        await tester.tap(find.byKey(ValueKey('owned-$id')));
        await frames(tester, const Duration(milliseconds: 700));
      }
      expect(repo.deck, [1, 2, 23]);
      expect(find.text('Boş'), findsNothing);
      final sfx = backend.sfx.map((e) => e.$1).toList();
      expect(sfx, [Sfx.cardFlip, Sfx.cardFlip, Sfx.rareReveal]);
      expect(
        find.byKey(const ValueKey('coverage-robot-false')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('slot-0')));
      await frames(tester, const Duration(milliseconds: 700));
      expect(repo.deck, [2, 23]);
      expect(backend.sfx.last.$1, Sfx.buttonTap);
    });
  });
}
