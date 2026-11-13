import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// SPEC §5.8 T3: `lib/app/theme/` dışındaki görsel kodda hex renk, süre veya yazı boyutu
/// sabiti yok. Kapsam = görsel kod: `lib/features`,
/// `lib/core/widgets` ve `lib/app` (SPEC ilk ikisini sayar). Görsel olmayan
/// zamanlama sabitleri (ağ tekrarı, ses solmaları, titreşim dizileri, sensör
/// pencereleri) `core/` servislerinde isimli sabitler olarak durur.
void main() {
  final forbidden = <String, RegExp>{
    'hex color': RegExp(r'Color\(0x'),
    'duration': RegExp(r'Duration\('),
    'font size': RegExp(r'fontSize:'),
  };

  const scanned = ['lib/features/', 'lib/core/widgets/', 'lib/app/'];

  bool skipped(String path) {
    final p = path.replaceAll(r'\', '/');
    return !scanned.any(p.startsWith) ||
        p.startsWith('lib/app/theme/') ||
        p.endsWith('.g.dart');
  }

  test('design literals live only in lib/app/theme/', () {
    final hits = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !skipped(f.path));
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final entry in forbidden.entries) {
          if (entry.value.hasMatch(lines[i])) {
            hits.add('${file.path}:${i + 1} ${entry.key}: ${lines[i].trim()}');
          }
        }
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });
}
