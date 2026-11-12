import '../../../../app/theme/motion.dart';

/// One phase of the intro, as fractions of the whole timeline.
final class RevealPhase {
  const RevealPhase(this.start, this.end);

  final double start;
  final double end;

  /// 0 before the phase, 1 after it, linear inside.
  double progress(double t) {
    if (t <= start) return 0;
    if (t >= end) return 1;
    return (t - start) / (end - start);
  }

  bool contains(double t) => t >= start && t < end;
}

/// Beats that make a sound / vibration (SPEC §4.3).
enum RevealBeat { charge, burst, land }

/// The reveal intro (SPEC §4.3, D7): charge → burst → emerge → fall →
/// land (squash, rebound, settle). Pure timing, no widgets: tested alone.
final class RevealTimeline {
  RevealTimeline({required bool legendary})
    : _parts = [
        AppMotion.revealCharge,
        AppMotion.revealBurst,
        legendary ? AppMotion.revealEmergeLegendary : AppMotion.revealEmerge,
        AppMotion.revealFall,
        AppMotion.revealSquash * 3,
      ] {
    total = _parts.fold(Duration.zero, (sum, d) => sum + d);
    final totalUs = total.inMicroseconds;
    var at = 0;
    final edges = <double>[0];
    for (final p in _parts) {
      at += p.inMicroseconds;
      edges.add(at / totalUs);
    }
    charge = RevealPhase(edges[0], edges[1]);
    burst = RevealPhase(edges[1], edges[2]);
    emerge = RevealPhase(edges[2], edges[3]);
    fall = RevealPhase(edges[3], edges[4]);
    land = RevealPhase(edges[4], edges[5]);
  }

  final List<Duration> _parts;

  late final Duration total;
  late final RevealPhase charge;
  late final RevealPhase burst;
  late final RevealPhase emerge;
  late final RevealPhase fall;
  late final RevealPhase land;

  /// Where each beat fires (fraction of the timeline).
  double beatAt(RevealBeat beat) => switch (beat) {
    RevealBeat.charge => charge.start,
    RevealBeat.burst => burst.start,
    RevealBeat.land => land.start,
  };

  /// Beats crossed when the timeline moves from [from] to [to].
  List<RevealBeat> beatsBetween(double from, double to) => [
    for (final b in RevealBeat.values)
      if ((from < beatAt(b) || (from == 0 && beatAt(b) == 0)) &&
          beatAt(b) <= to)
        b,
  ];

  /// Squash & stretch scale (x, y) during [land] (SPEC §4.3): squash, rebound,
  /// settle, each a third of the phase.
  static (double, double) squash(double p) {
    const keys = [(1.0, 1.0), (1.14, 0.82), (0.96, 1.06), (1.0, 1.0)];
    if (p <= 0) return keys.first;
    if (p >= 1) return keys.last;
    final seg = (p * 3).floor().clamp(0, 2);
    final local = p * 3 - seg;
    final a = keys[seg];
    final b = keys[seg + 1];
    return (a.$1 + (b.$1 - a.$1) * local, a.$2 + (b.$2 - a.$2) * local);
  }
}
