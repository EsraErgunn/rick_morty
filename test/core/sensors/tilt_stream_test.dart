import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/core/sensors/tilt_stream.dart';

/// Fake accelerometer that counts subscriptions.
class _FakeSensor {
  final List<StreamController<Gravity>> opened = [];

  int get live => opened.where((c) => c.hasListener).length;

  Stream<Gravity> open() {
    final c = StreamController<Gravity>();
    opened.add(c);
    return c.stream;
  }

  void emit(double x, double y, [double z = 6.9]) =>
      opened.last.add((x: x, y: y, z: z));
}

void main() {
  late _FakeSensor sensor;
  late TiltStream tilt;

  setUp(() {
    sensor = _FakeSensor();
    tilt = TiltStream(source: sensor.open);
  });

  tearDown(() => tilt.dispose());

  Future<List<Offset>> collect(void Function() feed) async {
    final out = <Offset>[];
    final sub = tilt.stream.listen(out.add);
    feed();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    return out;
  }

  test('first reading is the rest pose: (0, 0)', () async {
    final out = await collect(() => sensor.emit(1, 6.9));
    expect(out.single, Offset.zero);
  });

  test('low-pass: each step moves 15% toward the target', () async {
    const g = TiltStream.gravity;
    const step = TiltStream.fullTiltG * g * 0.5; // half deflection
    final out = await collect(() {
      sensor.emit(0, 6.9);
      for (var i = 0; i < 3; i++) {
        sensor.emit(-step, 6.9); // right edge down → +dx
      }
    });

    expect(out[1].dx, closeTo(0.5 * 0.15, 1e-9));
    expect(out[2].dx, closeTo(out[1].dx + 0.15 * (0.5 - out[1].dx), 1e-9));
    expect(out[3].dx, greaterThan(out[2].dx));
    expect(out.every((o) => o.dy == 0), isTrue);
  });

  test('clamps to [-1, 1] for large tilts', () async {
    final out = await collect(() {
      sensor.emit(0, 0);
      for (var i = 0; i < 200; i++) {
        sensor.emit(-20, 20);
      }
    });
    expect(out.last.dx, 1);
    expect(out.last.dy, -1);
    expect(out.every((o) => o.dx.abs() <= 1 && o.dy.abs() <= 1), isTrue);
  });

  test('sensor opens on first listener and closes on last cancel', () async {
    expect(tilt.activeSubscriptions, 0);
    final a = tilt.stream.listen((_) {});
    final b = tilt.stream.listen((_) {});
    expect(tilt.activeSubscriptions, 1);
    expect(sensor.opened, hasLength(1));

    await a.cancel();
    expect(tilt.activeSubscriptions, 1);
    await b.cancel();
    expect(tilt.activeSubscriptions, 0);
  });

  test('pause cancels the sensor; resume opens exactly one', () async {
    final sub = tilt.stream.listen((_) {});
    await Future<void>.delayed(Duration.zero);
    expect(sensor.live, 1);

    tilt.pause();
    await Future<void>.delayed(Duration.zero);
    expect(tilt.activeSubscriptions, 0);
    expect(sensor.live, 0);

    tilt
      ..resume()
      ..resume();
    await Future<void>.delayed(Duration.zero);
    expect(tilt.activeSubscriptions, 1);
    expect(sensor.opened, hasLength(2));
    expect(sensor.live, 1);
    await sub.cancel();
  });

  test('resume takes the new pose as rest', () async {
    final out = <Offset>[];
    final sub = tilt.stream.listen(out.add);
    sensor
      ..emit(0, 6.9)
      ..emit(-3, 6.9);
    tilt
      ..pause()
      ..resume();
    sensor.emit(-3, 6.9);
    await Future<void>.delayed(Duration.zero);

    expect(out.last, Offset.zero);
    await sub.cancel();
  });

  test('paused stream does not open the sensor for new listeners', () async {
    tilt.pause();
    final sub = tilt.stream.listen((_) {});
    expect(tilt.activeSubscriptions, 0);
    await sub.cancel();
  });
}
