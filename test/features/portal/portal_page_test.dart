import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:portalcards/core/audio/audio_assets.dart';
import 'package:portalcards/core/errors/failures.dart';
import 'package:portalcards/core/haptics/haptics_service.dart';
import 'package:portalcards/core/sensors/shake_detector.dart';
import 'package:portalcards/core/sensors/tilt_stream.dart';
import 'package:portalcards/core/widgets/game_card/card_art.dart';
import 'package:portalcards/core/widgets/game_card/flip_card.dart';
import 'package:portalcards/core/widgets/shader_cache.dart';
import 'package:portalcards/features/portal/presentation/bloc/portal_bloc.dart';
import 'package:portalcards/features/portal/presentation/bloc/portal_event.dart';
import 'package:portalcards/features/portal/presentation/pages/portal_page.dart';

import '../../helpers/cards.dart';
import 'portal_fakes.dart';

void main() {
  final shaders = ShaderCache(loader: (_) => Future.error(StateError('x')));
  setUpAll(shaders.load);
  setUp(() => CardArt.debugArtBuilder = testArt);
  tearDown(() => CardArt.debugArtBuilder = null);

  late StreamController<Gravity> motion;
  late Duration now;
  late RecordingFeedback rec;
  var battle = 0;

  Future<FakePortalRepository> pumpPage(
    WidgetTester tester, {
    FakePortalRepository? repo,
    bool deckReady = false,
  }) async {
    final r = repo ?? FakePortalRepository();
    motion = StreamController<Gravity>.broadcast();
    now = Duration.zero;
    rec = RecordingFeedback();
    final shake = ShakeDetector(source: () => motion.stream, clock: () => now);
    addTearDown(shake.dispose);
    await tester.pumpWidget(
      testApp(
        BlocProvider(
          create: (_) => PortalBloc(r)..add(const PortalStarted()),
          child: PortalPage(
            shaders: shaders,
            shake: shake,
            feedback: rec.feedback,
            deckReady: deckReady,
            onGoToBattle: () => battle++,
            onGoToCollection: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    return r;
  }

  Future<void> shakePhone(WidgetTester tester) async {
    for (final ms in [0, 20, 300, 320]) {
      now = Duration(milliseconds: ms);
      motion.add((x: ms % 300 == 0 ? 25.0 : 1.0, y: 0, z: 0));
      await tester.pump();
    }
  }

  testWidgets('first visit shows the shake hint and the open button', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(find.text('Telefonu salla!'), findsOneWidget);
    expect(find.text('Portalı aç · 100'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('no hint after the first portal', (tester) async {
    await pumpPage(tester, repo: FakePortalRepository(shakeHintSeen: true));
    expect(find.text('Telefonu salla!'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shaking the phone opens the portal and shows the card back', (
    tester,
  ) async {
    final repo = await pumpPage(tester);
    await shakePhone(tester);
    await tester.pump();

    expect(repo.opened, 1);
    expect(find.text('Çevirmek için dokun'), findsOneWidget);
    expect(find.text('Telefonu salla!'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the button opens too (fallback) with a tap sound', (
    tester,
  ) async {
    final repo = await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey('portal-open-button')));
    await tester.pump();
    expect(repo.opened, 1);
    expect(rec.sounds, contains(Sfx.buttonTap));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('not enough coins: message, haptic, no battle action', (
    tester,
  ) async {
    await pumpPage(
      tester,
      repo: FakePortalRepository(
        coins: 40,
        results: [left(const NotEnoughCoinsFailure(100, 40))],
      ),
    );
    await tester.tap(find.byKey(const ValueKey('portal-open-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.text('Portal için 100 coin gerekli. Savaşarak coin kazan.'),
      findsOneWidget,
    );
    expect(find.text('Savaşa git'), findsNothing);
    expect(rec.haptics, contains(HapticKind.light));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('with a full deck the message offers "Savaşa git"', (
    tester,
  ) async {
    await pumpPage(
      tester,
      deckReady: true,
      repo: FakePortalRepository(
        coins: 40,
        results: [left(const NotEnoughCoinsFailure(100, 40))],
      ),
    );
    await tester.tap(find.byKey(const ValueKey('portal-open-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Savaşa git'));
    expect(battle, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reveal: scene plays, tap flips, actions appear', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey('portal-open-button')));
    await tester.pump();
    // Legendary Rick: charge + burst + cinematic emerge + fall + land.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(FlipCard));
    // Gold sweep, flip, rays, then the actions fade in.
    await frames(tester, const Duration(milliseconds: 2500));

    expect(rec.sounds, containsAll([Sfx.cardFlip, Sfx.legendaryReveal]));
    expect(find.text('Yeni kart!'), findsOneWidget);
    expect(find.text('Tekrar aç'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
