import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `lib/core/game/` saf Dart'tır (mimari kurallar): Flutter yok, Hive yok,
/// Dio yok ve rastgelelik her zaman enjekte edilir.
void main() {
  final files = Directory('lib/core/game')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('game engine folder exists and has sources', () {
    expect(files, isNotEmpty);
  });

  test('imports no Flutter, dart:ui, Hive or Dio', () {
    final forbidden = RegExp(
      r'''^\s*(import|export)\s+['"](package:flutter|dart:ui|package:hive|package:dio)''',
      multiLine: true,
    );
    final hits = [
      for (final f in files)
        if (forbidden.hasMatch(f.readAsStringSync())) f.path,
    ];
    expect(hits, isEmpty);
  });

  test('never creates its own Random()', () {
    final created = RegExp(r'Random(\.secure)?\(');
    final hits = [
      for (final f in files)
        if (created.hasMatch(f.readAsStringSync())) f.path,
    ];
    expect(hits, isEmpty);
  });
}
