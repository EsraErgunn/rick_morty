import 'dart:io';

import 'package:flutter/services.dart';
import 'package:portalcards/app/theme/typography.dart';

/// Flutter ailesi başına paketlenmiş yazı tipi dosyaları (pubspec).
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

/// Altın görüntüler gerçek karakterler göstersin diye gerçek yazı tiplerini yükler (testler varsayılan
/// olarak kutu yazı tipi kullanır). Material Icons testlerde kutu olarak kalır; bu beklenen bir durum.
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
