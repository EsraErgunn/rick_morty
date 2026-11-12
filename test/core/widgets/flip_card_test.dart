import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/app/theme/card_style.dart';
import 'package:portalcards/app/theme/motion.dart';
import 'package:portalcards/core/widgets/game_card/card_art.dart';
import 'package:portalcards/core/widgets/game_card/card_back.dart';
import 'package:portalcards/core/widgets/game_card/flip_card.dart';
import 'package:portalcards/core/widgets/game_card/game_card.dart';

import '../../helpers/cards.dart';
import '../../helpers/fonts.dart';

const _front = ValueKey('flip-front');
const _back = ValueKey('flip-back');

void main() {
  late List<bool> flips;

  setUpAll(loadAppFonts);
  setUp(() {
    flips = [];
    CardArt.debugArtBuilder = testArt;
  });
  tearDown(() => CardArt.debugArtBuilder = null);

  Future<void> pumpFlip(WidgetTester tester, {bool reduce = false}) =>
      tester.pumpWidget(
        testApp(
          Center(
            child: SizedBox(
              width: CardMetrics.designWidth,
              child: FlipCard(
                front: GameCard(data: fixtureCard(1)),
                back: CardBack(facts: fixtureCard(1)),
                onFlipped: flips.add,
              ),
            ),
          ),
          reduceMotion: reduce,
        ),
      );

  testWidgets('starts on the front', (tester) async {
    await pumpFlip(tester);
    expect(find.byKey(_front), findsOneWidget);
    expect(find.byKey(_back), findsNothing);
  });

  testWidgets('tap flips to the back; only one face at any time', (
    tester,
  ) async {
    await pumpFlip(tester);
    await tester.tap(find.byType(FlipCard));

    // Sample the whole animation: exactly one face every frame.
    for (var t = 0; t < 10; t++) {
      await tester.pump(AppMotion.normal ~/ 10);
      final faces =
          find.byKey(_front).evaluate().length +
          find.byKey(_back).evaluate().length;
      expect(faces, 1);
    }
    await tester.pumpAndSettle();

    expect(find.byKey(_back), findsOneWidget);
    expect(find.text('Earth (C-137)'), findsOneWidget);
    expect(flips, [true]);
  });

  testWidgets('halfway (before 90°) the back is still hidden', (tester) async {
    await pumpFlip(tester);
    await tester.tap(find.byType(FlipCard));
    await tester.pump();
    await tester.pump(AppMotion.normal * 0.4);
    expect(find.byKey(_front), findsOneWidget);
    expect(find.byKey(_back), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('second tap flips back to the front', (tester) async {
    await pumpFlip(tester);
    await tester.tap(find.byType(FlipCard));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FlipCard));
    await tester.pumpAndSettle();

    expect(find.byKey(_front), findsOneWidget);
    expect(flips, [true, false]);
  });

  testWidgets('reduced motion swaps instantly, no rotation', (tester) async {
    await pumpFlip(tester, reduce: true);
    await tester.tap(find.byType(FlipCard));
    await tester.pump();

    expect(find.byKey(_back), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
    expect(flips, [true]);
  });

  testWidgets('disposes its controller (no ticker leak)', (tester) async {
    await pumpFlip(tester);
    await tester.tap(find.byType(FlipCard));
    await tester.pump(AppMotion.fast);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('plain back has no facts', (tester) async {
    await tester.pumpWidget(
      testApp(const SizedBox(width: 200, child: CardBack())),
    );
    expect(find.byKey(const ValueKey('card-back')), findsOneWidget);
    expect(find.text('Köken'), findsNothing);
  });
}
