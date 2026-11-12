import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// SPEC §5.8 T3 / plan T4: no hex color, duration or font size literal
/// outside `lib/app/theme/`. Generated l10n code is skipped.
void main() {
  final forbidden = <String, RegExp>{
    'hex color': RegExp(r'Color\(0x'),
    'duration': RegExp(r'Duration\('),
    'font size': RegExp(r'fontSize:'),
  };

  bool skipped(String path) {
    final p = path.replaceAll(r'\', '/');
    return p.startsWith('lib/app/theme/') ||
        p.startsWith('lib/l10n/') ||
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
