import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml')
      .readAsStringSync();

  test('release manifest asks for the INTERNET permission', () {
    // Bunu Flutter'dan yalnızca debug/profile manifestleri alır; bu olmadan
    // release derleme senkron yapamaz ve kart görsellerini indiremez.
    expect(manifest, contains('android.permission.INTERNET'));
  });

  test('cleartext traffic stays blocked', () {
    expect(manifest, contains('android:usesCleartextTraffic="false"'));
  });
}
