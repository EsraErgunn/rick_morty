import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml')
      .readAsStringSync();

  test('release manifest asks for the INTERNET permission', () {
    // Only the debug/profile manifests get it from Flutter; without it the
    // release build cannot sync or download card art.
    expect(manifest, contains('android.permission.INTERNET'));
  });

  test('cleartext traffic stays blocked', () {
    expect(manifest, contains('android:usesCleartextTraffic="false"'));
  });
}
