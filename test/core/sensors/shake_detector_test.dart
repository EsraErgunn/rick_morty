import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/core/sensors/shake_detector.dart';
import 'package:portalcards/core/sensors/tilt_stream.dart';

void main() {
  late StreamController<Gravity> sensor;
  late Duration now;
  late ShakeDetector detector;
  late int opened;
  late List<Duration> shakes;
  StreamSubscription<void>? sub;

  setUp(() {
    opened = 0;
    now = Duration.zero;
    shakes = [];
    sensor = StreamController<Gravity>.broadcast();
    detector = ShakeDetector(
      source: () {
        opened++;
        return sensor.stream;
      },
      clock: () => now,
    );
    sub = detector.shakes.listen((_) => shakes.add(now));
  });

  tearDown(() async {
    await sub?.cancel();
    await detector.dispose();
    await sensor.close();
  });

  /// One reading at time [ms] with magnitude [g] (on x).
  Future<void> at(int ms, double g) async {
    now = Duration(milliseconds: ms);
    sensor.add((x: g, y: 0, z: 0));
    await Future<void>.delayed(Duration.zero);
  }

  /// A peak: above the threshold, then back down.
  Future<void> peak(int ms) async {
    await at(ms, 20);
    await at(ms + 20, 2);
  }

  test('two peaks within 500 ms → one shake', () async {
    await peak(0);
    await peak(300);
    expect(shakes, [const Duration(milliseconds: 300)]);
  });

  test('a single peak is ignored', () async {
    await peak(0);
    await at(400, 3);
    expect(shakes, isEmpty);
  });

  test('peaks more than 500 ms apart do not count together', () async {
    await peak(0);
    await peak(700);
    expect(shakes, isEmpty);
    await peak(1000); // pairs with the 700 ms peak
    expect(shakes, hasLength(1));
  });

  test('holding above the threshold is one peak, not many', () async {
    for (var t = 0; t < 400; t += 20) {
      await at(t, 25);
    }
    expect(shakes, isEmpty);
  });

  test('1.5 s cooldown after a shake', () async {
    await peak(0);
    await peak(200);
    await peak(600);
    await peak(800);
    expect(shakes, hasLength(1));
    await peak(1800);
    await peak(2000);
    expect(shakes, hasLength(2));
  });

  test('normal handling (below 15 m/s²) never shakes', () async {
    for (var t = 0; t < 2000; t += 50) {
      await at(t, 12);
      await at(t + 25, 4);
    }
    expect(shakes, isEmpty);
  });

  test('pause closes the sensor; resume opens exactly one', () async {
    expect(detector.activeSubscriptions, 1);
    detector.pause();
    expect(detector.activeSubscriptions, 0);
    detector
      ..resume()
      ..resume();
    expect(detector.activeSubscriptions, 1);
    expect(opened, 2);
  });

  test('sensor closes when the last listener leaves', () async {
    await sub?.cancel();
    sub = null;
    expect(detector.activeSubscriptions, 0);
  });
}
