import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/app/theme/motion.dart';
import 'package:portalcards/features/portal/presentation/widgets/reveal_timeline.dart';

void main() {
  test('normal intro: charge, burst, emerge, fall, land in order', () {
    final t = RevealTimeline(legendary: false);
    expect(
      t.total,
      AppMotion.slow +
          AppMotion.fast +
          AppMotion.slow +
          AppMotion.normal +
          AppMotion.fast * 3,
    );
    expect(t.charge.start, 0);
    expect(t.charge.end, t.burst.start);
    expect(t.burst.end, t.emerge.start);
    expect(t.emerge.end, t.fall.start);
    expect(t.fall.end, t.land.start);
    expect(t.land.end, closeTo(1, 1e-9));
  });

  test('legendary emerges over the cinematic duration', () {
    final normal = RevealTimeline(legendary: false);
    final legendary = RevealTimeline(legendary: true);
    expect(
      legendary.total - normal.total,
      AppMotion.cinematic - AppMotion.slow,
    );
  });

  test('beats fire once when the timeline passes them', () {
    final t = RevealTimeline(legendary: false);
    expect(t.beatsBetween(0, 0.01), [RevealBeat.charge]);
    expect(t.beatsBetween(0.01, t.burst.start), [RevealBeat.burst]);
    expect(t.beatsBetween(t.burst.start, t.land.start - 0.001), isEmpty);
    expect(t.beatsBetween(t.land.start - 0.001, 1), [RevealBeat.land]);
    expect(t.beatsBetween(0, 1), RevealBeat.values);
  });

  test('phase progress is 0 before, 1 after, linear inside', () {
    const p = RevealPhase(0.2, 0.4);
    expect(p.progress(0.1), 0);
    expect(p.progress(0.3), closeTo(0.5, 1e-9));
    expect(p.progress(0.5), 1);
  });

  test('squash & stretch: squash, rebound, settle', () {
    expect(RevealTimeline.squash(0), (1.0, 1.0));
    final (sx, sy) = RevealTimeline.squash(1 / 3);
    expect(sx, closeTo(1.14, 1e-9));
    expect(sy, closeTo(0.82, 1e-9));
    final (rx, ry) = RevealTimeline.squash(2 / 3);
    expect(rx, closeTo(0.96, 1e-9));
    expect(ry, closeTo(1.06, 1e-9));
    expect(RevealTimeline.squash(1), (1.0, 1.0));
  });
}
