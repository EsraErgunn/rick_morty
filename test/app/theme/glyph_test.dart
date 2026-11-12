import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/app/theme/app_theme.dart';
import 'package:portalcards/app/theme/colors.dart';
import 'package:portalcards/app/theme/spacing.dart';
import 'package:portalcards/app/theme/typography.dart';

import '../../helpers/fonts.dart';
import 'ttf_reader.dart';

/// SPEC §5.8 T1: Turkish glyphs in every weight of both fonts.
const String turkish = 'ğşıİçöüĞŞÇÖÜ';

void main() {
  group('bundled font files', () {
    for (final path in fontFiles.values.expand((p) => p)) {
      final name = path.split('/').last;

      test('$name maps every Turkish glyph (no missing-glyph box)', () {
        final reader = TtfReader(File(path).readAsBytesSync());
        final missing = turkish.runes
            .where((cp) => !reader.codePoints().contains(cp))
            .map(String.fromCharCode)
            .toList();
        expect(missing, isEmpty);
      });

      test('$name has tabular figures (tnum)', () {
        final reader = TtfReader(File(path).readAsBytesSync());
        expect(reader.gsubFeatures(), contains('tnum'));
      });
    }

    test('each font family ships its OFL license', () {
      expect(File('assets/fonts/grandstander/OFL.txt').existsSync(), isTrue);
      expect(
        File('assets/fonts/atkinson_hyperlegible_next/OFL.txt').existsSync(),
        isTrue,
      );
    });

    test('pubspec declares both families with the bundled files', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('family: ${AppFonts.display}'));
      expect(pubspec, contains('family: ${AppFonts.body}'));
      for (final path in fontFiles.values.expand((p) => p)) {
        expect(pubspec, contains('asset: $path'));
      }
    });
  });

  group('type scale', () {
    test('matches SPEC 5.3 (caption 12 ... callout 56)', () {
      expect(
        [
          AppTypography.caption.fontSize,
          AppTypography.body.fontSize,
          AppTypography.title.fontSize,
          AppTypography.headline.fontSize,
          AppTypography.display.fontSize,
          AppTypography.callout.fontSize,
        ],
        [12, 16, 20, 25, 40, 56],
      );
    });

    test('display is at least 2.5x body', () {
      expect(
        AppTypography.display.fontSize! / AppTypography.body.fontSize!,
        greaterThanOrEqualTo(2.5),
      );
    });

    test('stat and coin styles use tabular figures', () {
      for (final style in [AppTypography.stat, AppTypography.coin]) {
        expect(
          style.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      }
    });
  });

  testWidgets('glyph sample renders in every style with its family', (
    tester,
  ) async {
    await loadAppFonts();
    const styles = <String, TextStyle>{
      'callout 900': AppTypography.callout,
      'display 900': AppTypography.display,
      'headline 900': AppTypography.headline,
      'title 700': AppTypography.title,
      'label 700': AppTypography.label,
      'body 400': AppTypography.body,
      'stat 700': AppTypography.stat,
      'caption 400': AppTypography.caption,
    };

    tester.view.physicalSize = const Size(1080, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: const ValueKey('sample'),
              child: ColoredBox(
                color: AppColors.voidBase,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in styles.entries)
                        Text(
                          '$turkish 0123 ${entry.key}',
                          key: ValueKey(entry.key),
                          style: entry.value,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    for (final entry in styles.entries) {
      final text = tester.widget<Text>(find.byKey(ValueKey(entry.key)));
      expect(text.style!.fontFamily, isIn(fontFiles.keys));
      expect(text.data, contains(turkish));
    }

    await expectLater(
      find.byKey(const ValueKey('sample')),
      matchesGoldenFile('goldens/glyph_sample.png'),
    );
  }, tags: ['golden']);
}
