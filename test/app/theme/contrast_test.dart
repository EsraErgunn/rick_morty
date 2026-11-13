import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/app/theme/colors.dart';

/// [0, 1] aralığındaki bir sRGB kanal değerinin WCAG 2.x göreli parlaklığı.
double _linear(double c) =>
    c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _linear(c.r) + 0.7152 * _linear(c.g) + 0.0722 * _linear(c.b);

double contrastRatio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

const double _body = 4.5;
const double _large = 3;

typedef _Pair = (String name, Color fg, Color bg, double min);

/// SPEC §5.8 T2'deki çiftler, artı arayüzün dayandığı yazı dışı çiftler.
/// Nadirlik çerçeveleri üstündeki yazı [AppColors.ink] (2026-11-12'de karar verildi).
const List<_Pair> _pairs = [
  ('paper on void', AppColors.paper, AppColors.voidBase, _body),
  ('paper on voidRaised', AppColors.paper, AppColors.voidRaised, _body),
  ('paperMuted on void', AppColors.paperMuted, AppColors.voidBase, _body),
  (
    'paperMuted on voidRaised',
    AppColors.paperMuted,
    AppColors.voidRaised,
    _body,
  ),
  ('ink on portal', AppColors.ink, AppColors.portal, _body),
  ('ink on warn', AppColors.ink, AppColors.warn, _body),
  ('ink on danger', AppColors.ink, AppColors.danger, _body),
  ('ink on rarityCommon', AppColors.ink, AppColors.rarityCommon, _body),
  ('ink on rarityRare', AppColors.ink, AppColors.rarityRare, _body),
  ('ink on rarityEpic', AppColors.ink, AppColors.rarityEpic, _body),
  ('ink on rarityLegendary', AppColors.ink, AppColors.rarityLegendary, _body),
  // Arka plan üstündeki renkli yazı ve göstergeler (düşük HP sayısı, ilerleme).
  ('warn on void', AppColors.warn, AppColors.voidBase, _body),
  ('danger on void', AppColors.danger, AppColors.voidBase, _body),
  ('portal on void', AppColors.portal, AppColors.voidBase, _large),
  (
    'portalHot focus ring on void',
    AppColors.portalHot,
    AppColors.voidBase,
    _large,
  ),
  // Kart gövdesine karşı çerçeve (yazı dışı grafik).
  (
    'rarityCommon frame on voidRaised',
    AppColors.rarityCommon,
    AppColors.voidRaised,
    _large,
  ),
  (
    'rarityRare frame on voidRaised',
    AppColors.rarityRare,
    AppColors.voidRaised,
    _large,
  ),
  (
    'rarityEpic frame on voidRaised',
    AppColors.rarityEpic,
    AppColors.voidRaised,
    _large,
  ),
  (
    'rarityLegendary frame on voidRaised',
    AppColors.rarityLegendary,
    AppColors.voidRaised,
    _large,
  ),
];

void main() {
  group('contrastRatio', () {
    test('black on white is 21:1', () {
      expect(
        contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21, 0.001),
      );
    });

    test('a color on itself is 1:1', () {
      expect(contrastRatio(AppColors.portal, AppColors.portal), 1);
    });

    test('is symmetric', () {
      expect(
        contrastRatio(AppColors.ink, AppColors.warn),
        contrastRatio(AppColors.warn, AppColors.ink),
      );
    });
  });

  group('token pairs meet WCAG thresholds', () {
    for (final (name, fg, bg, min) in _pairs) {
      test('$name is at least $min:1', () {
        final ratio = contrastRatio(fg, bg);
        expect(
          ratio,
          greaterThanOrEqualTo(min),
          reason: '$name measured ${ratio.toStringAsFixed(2)}:1',
        );
      });
    }
  });

  test('warn is not the legendary gold (no shared meaning)', () {
    expect(AppColors.warn, isNot(AppColors.rarityLegendary));
  });
}
