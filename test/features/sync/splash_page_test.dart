import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:portalcards/app/theme/app_theme.dart';
import 'package:portalcards/app/theme/motion.dart';
import 'package:portalcards/core/errors/failures.dart';
import 'package:portalcards/features/sync/domain/sync_repository.dart';
import 'package:portalcards/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:portalcards/features/sync/presentation/bloc/sync_event.dart';
import 'package:portalcards/features/sync/presentation/pages/splash_page.dart';
import 'package:portalcards/l10n/app_localizations.dart';

import 'fake_sync_repository.dart';

void main() {
  late int done;

  setUp(() => done = 0);

  Future<void> pumpSplash(WidgetTester tester, FakeSyncRepository repo) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: BlocProvider(
            create: (_) => SyncBloc(repo)..add(const SyncStarted()),
            child: SplashPage(onDone: () => done++),
          ),
        ),
      );

  testWidgets('shows progress as bar, percentage and counter', (tester) async {
    final repo = FakeSyncRepository(
      progress: const [SyncProgress(downloaded: 421, total: 1003)],
      hold: true,
    );
    await pumpSplash(tester, repo);
    await tester.pump();
    await tester.pump(AppMotion.normal);

    expect(find.text('Evrenler indiriliyor'), findsOneWidget);
    expect(find.text('%41'), findsOneWidget);
    expect(find.text('421 / 1003'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey('sync-progress-bar')),
    );
    expect(bar.value, closeTo(421 / 1003, 0.001));

    repo.release();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('network failure: message + Tekrar dene; retry resumes', (
    tester,
  ) async {
    final repo = FakeSyncRepository(
      results: [left(const NetworkFailure()), right(unit)],
    );
    await pumpSplash(tester, repo);
    await tester.pump();
    await tester.pump(AppMotion.normal);

    expect(
      find.text('Bağlantı koptu. Kaldığın yerden devam edeceğiz.'),
      findsOneWidget,
    );
    expect(done, 0);

    await tester.tap(find.widgetWithText(FilledButton, 'Tekrar dene'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(repo.runs, 2);
    expect(done, 1);
  });

  testWidgets('storage failure shows the storage message', (tester) async {
    await pumpSplash(
      tester,
      FakeSyncRepository(results: [left(const StorageFailure())]),
    );
    await tester.pump();
    await tester.pump(AppMotion.normal);

    expect(find.text('Veriler kaydedilemedi. Tekrar dene.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets(
    'fast sync (already synced) finishes without showing the portal',
    (tester) async {
      await pumpSplash(tester, FakeSyncRepository());
      await tester.pump();

      expect(done, 1);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('portal-loader')),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('slow sync: menu opens only after the portal settles', (
    tester,
  ) async {
    final repo = FakeSyncRepository(hold: true);
    await pumpSplash(tester, repo);
    await tester.pump(AppMotion.loaderShowDelay);
    await tester.pump(const Duration(seconds: 1));

    repo.release();
    await tester.pump();
    expect(done, 0); // still closing the portal

    // Portal closes (normal) plus a frame for the post-frame callback.
    await tester.pump(AppMotion.normal);
    await tester.pump(AppMotion.fast);
    expect(done, 1);
  });
}
