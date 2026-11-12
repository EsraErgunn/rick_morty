import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:portalcards/core/storage/hive_init.dart';

/// Gives each test a fresh Hive directory and cleans it up afterwards.
/// Returns a getter for the current directory path.
String Function() useTempHive() {
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('portalcards_hive_');
    initHive(dir.path);
  });
  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });
  return () => dir.path;
}
