import '../../../../app/theme/motion.dart';

/// Girişin bir aşaması, tüm zaman çizelgesinin kesirleri olarak.
final class RevealPhase {
  const RevealPhase(this.start, this.end);

  final double start;
  final double end;

  /// Aşamadan önce 0, sonra 1, içinde doğrusal.
  double progress(double t) {
    if (t <= start) return 0;
    if (t >= end) return 1;
    return (t - start) / (end - start);
  }

  bool contains(double t) => t >= start && t < end;
}

/// Ses / titreşim çıkaran vuruşlar (SPEC §4.3).
enum RevealBeat { charge, burst, land }

/// Açılış girişi (SPEC §4.3, D7): şarj → patlama → çıkış → düşüş →
/// iniş (basılma, sekme, yerleşme). Yalnızca zamanlama, widget yok: tek başına test edilir.
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

  /// Her vuruşun tetiklendiği yer (zaman çizelgesinin kesri).
  double beatAt(RevealBeat beat) => switch (beat) {
    RevealBeat.charge => charge.start,
    RevealBeat.burst => burst.start,
    RevealBeat.land => land.start,
  };

  /// Zaman çizelgesi [from]'dan [to]'ya geçerken aşılan vuruşlar.
  List<RevealBeat> beatsBetween(double from, double to) => [
    for (final b in RevealBeat.values)
      if ((from < beatAt(b) || (from == 0 && beatAt(b) == 0)) &&
          beatAt(b) <= to)
        b,
  ];

  /// [land] sırasında basılma-esneme ölçeği (x, y) (SPEC §4.3): basılma, sekme,
  /// yerleşme; her biri aşamanın üçte biri.
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
