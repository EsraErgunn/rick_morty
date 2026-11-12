import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_tilt/flutter_tilt.dart';

import '../../../app/theme/card_style.dart';
import '../../sensors/tilt_stream.dart';

/// Builds the card; [tilt] is the current tilt for the holo layer.
typedef TiltedBuilder = Widget Function(
  BuildContext context,
  ValueListenable<Offset> tilt,
);

/// 3D tilt + light for a card (sensors rules). flutter_tilt's own sensors
/// are off; a [TiltController] is fed from [TiltStream], and touch drag
/// stays on as the fallback. Both inputs reach `onGestureMove` (spike
/// 2026-11-12), so [TiltedBuilder]'s `tilt` is one value for 3D tilt and
/// holo: flutter_tilt `areaProgress`, (1, 1) = top-left tilted down.
///
/// The sensor pauses when the app goes to the background.
/// All flutter_tilt usage stays in this file (plan risk: API churn).
class TiltingGameCard extends StatefulWidget {
  const TiltingGameCard({
    required this.tiltStream,
    required this.builder,
    super.key,
  });

  final TiltStream tiltStream;
  final TiltedBuilder builder;

  @override
  State<TiltingGameCard> createState() => _TiltingGameCardState();
}

class _TiltingGameCardState extends State<TiltingGameCard>
    with WidgetsBindingObserver {
  final TiltController _controller = TiltController();
  final ValueNotifier<Offset> _tilt = ValueNotifier(Offset.zero);
  StreamSubscription<Offset>? _sensor;
  Size _size = Size.zero;

  static const int _fps = 60;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sensor = widget.tiltStream.stream.listen(_onSensor);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.tiltStream.resume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      widget.tiltStream.pause();
    }
  }

  /// Sensor [-1, 1] → a point inside the card (center = rest).
  void _onSensor(Offset t) {
    if (_size.isEmpty) return;
    final half = _size.center(Offset.zero);
    final p = Offset(half.dx * (1 + t.dx), half.dy * (1 - t.dy));
    _controller.move(
      position: Offset(
        p.dx.clamp(0, _size.width - 1),
        p.dy.clamp(0, _size.height - 1),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_sensor?.cancel());
    unawaited(_controller.dispose());
    _tilt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _size = constraints.biggest;
      return Tilt.base(
        tiltController: _controller,
        fps: _fps,
        tiltConfig: const TiltConfig(
          angle: CardMetrics.tiltAngle,
          enableGestureSensors: false,
        ),
        lightConfig: const LightConfig(maxIntensity: CardMetrics.tiltLight),
        // flutter_tilt shadows are blurred; SPEC §5.4 allows no blur
        // outside the portal and holo, so the hard card outline stays.
        shadowConfig: const ShadowBaseConfig(disable: true),
        borderRadius: BorderRadius.circular(0),
        clipBehavior: Clip.none,
        onGestureMove: (data, _) => _tilt.value = data.areaProgress,
        onGestureLeave: (data, _) => _tilt.value = data.areaProgress,
        child: widget.builder(context, _tilt),
      );
    },
  );
}
