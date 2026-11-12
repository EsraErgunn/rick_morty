import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:portalcards/core/errors/failures.dart';
import 'package:portalcards/features/portal/presentation/bloc/portal_bloc.dart';
import 'package:portalcards/features/portal/presentation/bloc/portal_event.dart';
import 'package:portalcards/features/portal/presentation/bloc/portal_state.dart';

import 'portal_fakes.dart';

void main() {
  final rick = resultFor(1);

  blocTest<PortalBloc, PortalState>(
    'PortalStarted loads coins and shows the hint on the first visit',
    build: () => PortalBloc(FakePortalRepository()),
    act: (b) => b.add(const PortalStarted()),
    expect: () => const [PortalState(coins: 300, showShakeHint: true)],
  );

  blocTest<PortalBloc, PortalState>(
    'no hint once a portal was opened before',
    build: () => PortalBloc(FakePortalRepository(shakeHintSeen: true)),
    act: (b) => b.add(const PortalStarted()),
    expect: () => const [PortalState(coins: 300)],
  );

  blocTest<PortalBloc, PortalState>(
    'shake opens: opening, then revealing with the saved result',
    build: () => PortalBloc(FakePortalRepository()),
    seed: () => const PortalState(coins: 300, showShakeHint: true),
    act: (b) => b.add(const PortalShaken()),
    expect: () => [
      const PortalState(
        phase: PortalPhase.opening,
        coins: 300,
        showShakeHint: true,
      ),
      PortalState(phase: PortalPhase.revealing, coins: 200, result: rick),
    ],
  );

  blocTest<PortalBloc, PortalState>(
    'the button does the same (fallback)',
    build: () => PortalBloc(FakePortalRepository()),
    act: (b) => b.add(const PortalOpenRequested()),
    skip: 1,
    expect: () => [
      PortalState(phase: PortalPhase.revealing, coins: 200, result: rick),
    ],
  );

  blocTest<PortalBloc, PortalState>(
    'not enough coins: back to idle and the shake tick increases',
    build: () => PortalBloc(
      FakePortalRepository(
        coins: 40,
        results: [left(const NotEnoughCoinsFailure(100, 40))],
      ),
    ),
    seed: () => const PortalState(coins: 40),
    act: (b) => b.add(const PortalOpenRequested()),
    expect: () => const [
      PortalState(phase: PortalPhase.opening, coins: 40),
      PortalState(coins: 40, notEnoughCoins: 1),
    ],
  );

  blocTest<PortalBloc, PortalState>(
    'a storage failure keeps the portal idle with the failure',
    build: () => PortalBloc(
      FakePortalRepository(results: [left(const StorageFailure())]),
    ),
    act: (b) => b.add(const PortalOpenRequested()),
    skip: 1,
    expect: () => const [PortalState(failure: StorageFailure())],
  );

  test('shake while opening or revealing is ignored (AC6)', () async {
    final repo = FakePortalRepository(hold: true);
    final bloc = PortalBloc(repo)
      ..add(const PortalShaken())
      ..add(const PortalShaken())
      ..add(const PortalOpenRequested());
    await Future<void>.delayed(Duration.zero);
    repo.gate.complete();
    await bloc.stream.firstWhere((s) => s.phase == PortalPhase.revealing);
    bloc.add(const PortalShaken());
    await Future<void>.delayed(Duration.zero);

    expect(repo.opened, 1);
    await bloc.close();
  });

  blocTest<PortalBloc, PortalState>(
    'RevealFinished → revealed; PortalReset → idle without the result',
    build: () => PortalBloc(FakePortalRepository(coins: 200)),
    seed: () =>
        PortalState(phase: PortalPhase.revealing, coins: 200, result: rick),
    act: (b) => b
      ..add(const RevealFinished())
      ..add(const PortalReset()),
    expect: () => [
      PortalState(phase: PortalPhase.revealed, coins: 200, result: rick),
      const PortalState(coins: 200),
    ],
  );
}
