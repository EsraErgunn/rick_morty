import 'dart:io';

import 'package:flutter/services.dart';
import 'package:portalcards/app/theme/typography.dart';

/// Bundled font files per Flutter family (pubspec).
const Map<String, List<String>> fontFiles = {
  AppFonts.display: [
    'assets/fonts/grandstander/Grandstander-Bold.ttf',
    'assets/fonts/grandstander/Grandstander-Black.ttf',
  ],
  AppFonts.body: [
    'assets/fonts/atkinson_hyperlegible_next/AtkinsonHyperlegibleNext-Regular.ttf',
    'assets/fonts/atkinson_hyperlegible_next/AtkinsonHyperlegibleNext-Bold.ttf',
  ],
};

/// Loads the real fonts so goldens show real glyphs (tests use a box font
/// by default). Material Icons stay as boxes in tests; that is expected.
Future<void> loadAppFonts() async {
  for (final entry in fontFiles.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      final bytes = File(path).readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}
