import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/core/audio/audio_assets.dart';
import 'package:portalcards/core/audio/audio_service.dart';
import 'package:portalcards/core/feedback/ui_feedback.dart';
import 'package:portalcards/core/haptics/haptics_service.dart';
import 'package:portalcards/core/widgets/shader_cache.dart';
import 'package:portalcards/features/menu/domain/menu_repository.dart';
import 'package:portalcards/features/menu/presentation/bloc/menu_bloc.dart';
import 'package:portalcards/features/menu/presentation/bloc/menu_event.dart';
import 'package:portalcards/features/menu/presentation/bloc/menu_state.dart';
import 'package:portalcards/features/menu/presentation/pages/menu_page.dart';

import '../../helpers/fake_audio.dart';
import '../../helpers/cards.dart';

class _Repo implements MenuRepository {
  _Repo(this.summary);

  MenuSummary summary;

  @override
  MenuSummary load() => summary;
}

MenuSummary _summary({int owned = 0, int deck = 0, int coins = 300}) =>
    MenuSummary(
      coins: coins,
      owned: owned,
      totalCharacters: 826,
      deckSize: deck,
      albumsCompleted: 0,
      albumsTotal: 51,
    );

void main() {
  final shaders = ShaderCache(loader: (_) => Future.error(StateError('x')));
  setUpAll(shaders.load);

  blocTest<MenuBloc, MenuState>(
    'MenuStarted loads the summary',
    build: () => MenuBloc(_Repo(_summary(owned: 3))),
    act: (b) => b.add(const MenuStarted()),
    expect: () => [
      MenuState(status: MenuStatus.success, summary: _summary(owned: 3)),
    ],
  );

  late FakeBackend backend;
  late List<String> went;

  Future<_Repo> pumpMenu(WidgetTester tester, MenuSummary s) async {
    backend = FakeBackend();
    went = [];
    final audio = AudioService(backend: backend);
    final repo = _Repo(s);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      testApp(
        BlocProvider(
          create: (_) => MenuBloc(repo)..add(const MenuStarted()),
          child: MenuPage(
            shaders: shaders,
            audio: audio,
            feedback: UiFeedback(
              audio: audio,
              haptics: HapticsService(driver: (_) async {}),
            ),
            actions: MenuActions(
              portal: () => went.add('portal'),
              collection: () => went.add('collection'),
              deck: () => went.add('deck'),
              battle: () => went.add('battle'),
              album: () => went.add('album'),
              settings: () => went.add('settings'),
            ),
          ),
        ),
      ),
    );
    await frames(tester, const Duration(seconds: 1));
    return repo;
  }

  testWidgets('shows coins and counts; menu music starts', (tester) async {
    await pumpMenu(tester, _summary(owned: 84, deck: 3));
    expect(find.text('Koleksiyon'), findsOneWidget);
    expect(find.text('84/826'), findsOneWidget);
    expect(find.text('3/3'), findsOneWidget);
    expect(find.text('0/51'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
    expect(backend.music.single.track, Music.menuLoop);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('battle is disabled with the hint until the deck is full', (
    tester,
  ) async {
    await pumpMenu(tester, _summary(owned: 2, deck: 2));
    expect(find.text('Destene 3 kart ekle'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('menu-battle')));
    expect(went, isEmpty);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('full deck: battle opens, with a tap sound', (tester) async {
    await pumpMenu(tester, _summary(owned: 5, deck: 3));
    expect(find.text('Destene 3 kart ekle'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('menu-battle')));
    expect(went, ['battle']);
    expect(backend.sfx.map((e) => e.$1), contains(Sfx.buttonTap));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the portal button breathes only while the collection is empty', (
    tester,
  ) async {
    await pumpMenu(tester, _summary());
    expect(find.byKey(const ValueKey('breathing-on')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));

    await pumpMenu(tester, _summary(owned: 1));
    expect(find.byKey(const ValueKey('breathing-off')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('coins changing plays the coin sound', (tester) async {
    final repo = await pumpMenu(tester, _summary());
    repo.summary = _summary(coins: 1300);
    tester
        .element(find.byType(MenuPage))
        .read<MenuBloc>()
        .add(const MenuStarted());
    await frames(tester, const Duration(seconds: 1));
    expect(backend.sfx.map((e) => e.$1), contains(Sfx.coin));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('entries navigate', (tester) async {
    await pumpMenu(tester, _summary(owned: 1));
    await tester.tap(find.byKey(const ValueKey('menu-open-portal')));
    await tester.tap(find.text('Koleksiyon'));
    await tester.tap(find.byTooltip('Ayarlar'));
    expect(went, ['portal', 'collection', 'settings']);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
