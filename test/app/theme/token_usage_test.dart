import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// SPEC §5.8 T3: no hex color, duration or font size literal in visual code
/// outside `lib/app/theme/`. Scope = visual code: `lib/features`,
/// `lib/core/widgets` and `lib/app` (SPEC names the first two). Non-visual
/// timing constants (network retry, audio fades, haptic sequences, sensor
/// windows) live as named constants in their `core/` services.
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
