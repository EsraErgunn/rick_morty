import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/core/logging/app_logger.dart';

void main() {
  late List<(String, int)> records;

  setUp(() {
    records = [];
    AppLogger.sink = (
      message, {
      required name,
      required level,
      error,
      stackTrace,
    }) => records.add((message, level));
  });

  tearDown(AppLogger.reset);

  test('writes with rising levels when enabled', () {
    AppLogger.enabled = true;

    AppLogger.debug('d');
    AppLogger.info('i');
    AppLogger.warning('w');
    AppLogger.error('e');

    expect(records.map((r) => r.$1), ['d', 'i', 'w', 'e']);
    final levels = records.map((r) => r.$2).toList();
    expect(levels, orderedEquals([...levels]..sort()));
  });

  test('writes nothing when disabled (release and profile builds)', () {
    AppLogger.enabled = false;

    AppLogger.debug('d');
    AppLogger.error('e', StateError('x'));

    expect(records, isEmpty);
  });

  test('no print( call anywhere in lib/', () {
    final hits = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where(
          (f) => RegExp(r'(^|[^\w.])print\(').hasMatch(f.readAsStringSync()),
        )
        .map((f) => f.path)
        .toList();
    expect(hits, isEmpty);
  });
}
