import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/app/theme/card_style.dart';
import 'package:portalcards/app/theme/colors.dart';
import 'package:portalcards/core/game/rarity.dart';
import 'package:portalcards/core/widgets/game_card/card_art.dart';
import 'package:portalcards/core/widgets/game_card/game_card.dart';
import 'package:portalcards/core/widgets/game_card/rarity_frame_painter.dart';

import '../../helpers/cards.dart';
import '../../helpers/fonts.dart';

Future<void> _pumpCard(WidgetTester tester, int id) async {
  await tester.pumpWidget(
    testApp(
      Center(
        child: SizedBox(
          width: CardMetrics.designWidth,
          child: GameCard(data: fixtureCard(id)),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(loadAppFonts);
  setUp(() => CardArt.debugArtBuilder = testArt);
  tearDown(() => CardArt.debugArtBuilder = null);

  group('rarity frames (SPEC 5.5)', () {
    test('width, color and corners per rarity', () {
      expect(Rarity.values.map((r) => RarityStyle.of(r).frameWidth), [
        4,
        5,
        6,
        7,
      ]);
      expect(Rarity.values.map((r) => RarityStyle.of(r).color), [
        AppColors.rarityCommon,
        AppColors.rarityRare,
        AppColors.rarityEpic,
        AppColors.rarityLegendary,
      ]);
      expect(Rarity.values.map((r) => RarityStyle.of(r).notch), [0, 0, 6, 6]);
      expect(RarityStyle.of(Rarity.rare).innerLine, isTrue);
      expect(Rarity.values.where((r) => RarityStyle.of(r).emblem), [
        Rarity.legendary,
      ]);
    });

    for (final id in oneCardPerRarity) {
      final data = fixtureCard(id);
      testWidgets('${data.name} (${data.rarity.name}) uses its frame', (
        tester,
      ) async {
        await _pumpCard(tester, id);
        final paint = tester.widget<CustomPaint>(
          find.byKey(ValueKey('card-front-${data.rarity.name}')),
        );
        final painter = paint.painter! as RarityFramePainter;
        expect(painter.style.color, RarityStyle.of(data.rarity).color);
        expect(
          find.byKey(const ValueKey('legendary-emblem')),
          data.rarity == Rarity.legendary ? findsOneWidget : findsNothing,
        );
      });
    }
  });

  testWidgets('Rick shows name, type, rarity name and 2x2 stats', (
    tester,
  ) async {
    await _pumpCard(tester, 1);
    expect(find.text('Rick Sanchez'), findsOneWidget);
    expect(find.text('İnsan'), findsOneWidget);
    expect(find.text('Efsanevi'), findsOneWidget);
    expect(find.byIcon(CardTypeIcons.of(fixtureCard(1).type)), findsOneWidget);
    for (final label in ['Can', 'Saldırı', 'Savunma', 'Hız']) {
      expect(find.text(label), findsOneWidget);
    }
    for (final value in ['152', '33', '17']) {
      expect(find.text(value), findsWidgets);
    }
    expect(find.text('Zombi'), findsNothing);
  });

  testWidgets('Conroy (Dead) shows the Zombi passive', (tester) async {
    await _pumpCard(tester, 71);
    expect(find.text('Zombi'), findsOneWidget);
    expect(find.text('Robot'), findsOneWidget);
    expect(find.text('Sıradan'), findsOneWidget);
  });

  testWidgets('image error shows the ink silhouette with the name', (
    tester,
  ) async {
    CardArt.debugArtBuilder = (url, name) => InkSilhouette(name: name);
    await _pumpCard(tester, 23);
    expect(find.byKey(const ValueKey('ink-silhouette')), findsOneWidget);
    expect(find.text('Arcade Alien'), findsNWidgets(2)); // plate + silhouette
  });

  testWidgets('scales to any width at 5:7', (tester) async {
    await tester.pumpWidget(
      testApp(
        Center(
          child: SizedBox(width: 100, child: GameCard(data: fixtureCard(2))),
        ),
      ),
    );
    final size = tester.getSize(find.byType(GameCard));
    expect(size.width, 100);
    expect(size.height, closeTo(140, 0.01));
  });

  testWidgets('featured cards (Rick) get the badge; others do not', (
    tester,
  ) async {
    await _pumpCard(tester, 1);
    expect(find.byKey(const ValueKey('featured-badge')), findsOneWidget);
    await _pumpCard(tester, 71);
    expect(find.byKey(const ValueKey('featured-badge')), findsNothing);
  });

  testWidgets('hideArt leaves the art window empty', (tester) async {
    await tester.pumpWidget(
      testApp(
        SizedBox(
          width: CardMetrics.designWidth,
          child: GameCard(data: fixtureCard(1), hideArt: true),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('art-empty')), findsOneWidget);
  });

  testWidgets('golden: one card per rarity', (tester) async {
    tester.view.physicalSize = const Size(1140, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      testApp(
        RepaintBoundary(
          key: const ValueKey('rarity-row'),
          child: ColoredBox(
            color: AppColors.voidBase,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  for (final id in oneCardPerRarity)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: CardMetrics.designWidth,
                        child: GameCard(data: fixtureCard(id)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byKey(const ValueKey('rarity-row')),
      matchesGoldenFile('goldens/game_card_rarities.png'),
    );
  }, tags: ['golden']);
}
