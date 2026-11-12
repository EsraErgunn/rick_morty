import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/core/haptics/haptics_service.dart';
import 'package:portalcards/core/storage/player_state.dart';

void main() {
  late List<HapticKind> sent;
  late HapticsService haptics;

  setUp(() {
    sent = [];
    haptics = HapticsService(driver: (k) async => sent.add(k));
  });

  test('moments map to the rules table', () {
    expect(HapticsService.kindOf(HapticMoment.buttonTap), HapticKind.selection);
    expect(HapticsService.kindOf(HapticMoment.cardFlip), HapticKind.light);
    expect(HapticsService.kindOf(HapticMoment.hit), HapticKind.medium);
    expect(HapticsService.kindOf(HapticMoment.crit), HapticKind.heavy);
    expect(
      HapticsService.kindOf(HapticMoment.superEffective),
      HapticKind.heavy,
    );
    expect(HapticsService.kindOf(HapticMoment.portalOpen), HapticKind.heavy);
  });

  test('plays one vibration for a normal moment', () async {
    await haptics.play(HapticMoment.cardFlip);
    expect(sent, [HapticKind.light]);
  });

  testWidgets('legendary: heavy, 80 ms, heavy, 120 ms, heavy', (tester) async {
    unawaited(haptics.play(HapticMoment.legendaryReveal));
    await tester.pump();
    expect(sent, [HapticKind.heavy]);
    await tester.pump(const Duration(milliseconds: 79));
    expect(sent, hasLength(1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(sent, hasLength(2));
    await tester.pump(const Duration(milliseconds: 119));
    expect(sent, hasLength(2));
    await tester.pump(const Duration(milliseconds: 1));
    expect(sent, [HapticKind.heavy, HapticKind.heavy, HapticKind.heavy]);
  });

  test('haptics off: no call', () async {
    haptics.applySettings(const PlayerSettings(hapticsEnabled: false));
    await haptics.play(HapticMoment.crit);
    await haptics.play(HapticMoment.legendaryReveal);
    expect(sent, isEmpty);
  });

  test('starts with the stored setting', () {
    final off = HapticsService(
      driver: (k) async => sent.add(k),
      settings: const PlayerSettings(hapticsEnabled: false),
    );
    expect(off.enabled, isFalse);
  });

  testWidgets('the default driver calls the HapticFeedback channel', (
    tester,
  ) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add('${call.method} ${call.arguments}');
        return null;
      },
    );
    await HapticsService().play(HapticMoment.hit);
    expect(calls.single, contains('HapticFeedback.vibrate'));
    expect(calls.single, contains('mediumImpact'));
  });
}
