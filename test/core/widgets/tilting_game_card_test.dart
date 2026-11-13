import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/core/sensors/tilt_stream.dart';
import 'package:portalcards/core/widgets/game_card/tilting_game_card.dart';

/// Sahte ivmeölçer: açık abonelikleri sayar.
class _Sensor {
  final List<StreamController<Gravity>> opened = [];

  int get live => opened.where((c) => c.hasListener).length;

  Stream<Gravity> open() {
    final c = StreamController<Gravity>();
    opened.add(c);
    return c.stream;
  }

  void emit(double x, double y) => opened.last.add((x: x, y: y, z: 6.9));
}

void main() {
  late _Sensor sensor;
  late TiltStream tiltStream;
  ValueListenable<Offset>? tilt;

  setUp(() {
    sensor = _Sensor();
    tiltStream = TiltStream(source: sensor.open);
    tilt = null;
  });

  tearDown(() => tiltStream.dispose());

  Future<void> pumpCard(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 250,
            height: 350,
            child: TiltingGameCard(
              tiltStream: tiltStream,
              builder: (context, t) {
                tilt = t;
                return const ColoredBox(
                  key: ValueKey('card'),
                  color: Color(0xFF223344),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> tiltPhone(WidgetTester tester, double x, double y) async {
    for (var i = 0; i < 30; i++) {
      sensor.emit(x, y);
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  testWidgets('exactly one sensor subscription while the card is shown', (
    tester,
  ) async {
    await pumpCard(tester);
    expect(tiltStream.activeSubscriptions, 1);
    expect(sensor.live, 1);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tiltStream.activeSubscriptions, 0);
    expect(sensor.live, 0);
  });

  testWidgets('tilting the phone updates the holo tilt value', (tester) async {
    await pumpCard(tester);
    sensor.emit(0, 6.9); // durma pozu
    await tester.pump(const Duration(milliseconds: 20));
    expect(tilt!.value, Offset.zero);

    await tiltPhone(tester, -3, 6.9); // sağ kenar aşağı
    expect(tilt!.value, isNot(Offset.zero));
    expect(tilt!.value.dx.abs(), greaterThan(0.1));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('dragging on the card also tilts it (fallback)', (tester) async {
    await pumpCard(tester);
    final center = tester.getCenter(find.byKey(const ValueKey('card')));
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(80, -100));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveBy(const Offset(5, -5));
    await tester.pump(const Duration(milliseconds: 50));

    expect(tilt!.value, isNot(Offset.zero));
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('app in background closes the sensor; resume reopens one', (
    tester,
  ) async {
    await pumpCard(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(tiltStream.activeSubscriptions, 0);
    expect(sensor.live, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tiltStream.activeSubscriptions, 1);
    expect(sensor.live, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
