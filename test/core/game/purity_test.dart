import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `lib/core/game/` is pure Dart (architecture rules): no Flutter, no Hive,
/// no Dio, and randomness is always injected.
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
