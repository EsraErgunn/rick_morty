import 'package:flutter/services.dart';

import '../storage/player_state.dart';

/// Basic vibration kinds (Flutter `HapticFeedback`).
enum HapticKind { selection, light, medium, heavy }

/// Sends one vibration; injected so tests need no platform channel.
typedef HapticDriver = Future<void> Function(HapticKind kind);

Future<void> _platform(HapticKind kind) => switch (kind) {
  HapticKind.selection => HapticFeedback.selectionClick(),
  HapticKind.light => HapticFeedback.lightImpact(),
  HapticKind.medium => HapticFeedback.mediumImpact(),
  HapticKind.heavy => HapticFeedback.heavyImpact(),
};

/// Moments that vibrate (animation-audio rules, SPEC §4).
enum HapticMoment {
  buttonTap,
  toggle,
  coin,
  cardFlip,
  notEnoughCoins,
  portalCharge,
  cardLand,
  hit,
  rareReveal,
  crit,
  superEffective,
  portalOpen,
  legendaryReveal,
}

/// All vibration goes through here; respects `hapticsEnabled`.
class HapticsService {
  HapticsService({
    this._driver = _platform,
    PlayerSettings settings = const PlayerSettings(),
  }) : _enabled = settings.hapticsEnabled;

  /// Legendary reveal: heavy → 80 ms → heavy → 120 ms → heavy (rules).
  static const List<Duration> legendaryGaps = [
    Duration(milliseconds: 80),
    Duration(milliseconds: 120),
  ];

  final HapticDriver _driver;
  bool _enabled;

  bool get enabled => _enabled;

  void applySettings(PlayerSettings settings) =>
      _enabled = settings.hapticsEnabled;

  static HapticKind kindOf(HapticMoment moment) => switch (moment) {
    HapticMoment.buttonTap ||
    HapticMoment.toggle ||
    HapticMoment.coin => HapticKind.selection,
    HapticMoment.cardFlip || HapticMoment.notEnoughCoins => HapticKind.light,
    HapticMoment.portalCharge ||
    HapticMoment.cardLand ||
    HapticMoment.hit ||
    HapticMoment.rareReveal => HapticKind.medium,
    HapticMoment.crit ||
    HapticMoment.superEffective ||
    HapticMoment.portalOpen ||
    HapticMoment.legendaryReveal => HapticKind.heavy,
  };

  Future<void> play(HapticMoment moment) async {
    if (!_enabled) return;
    await _driver(kindOf(moment));
    if (moment != HapticMoment.legendaryReveal) return;
    for (final gap in legendaryGaps) {
      await Future<void>.delayed(gap);
      if (!_enabled) return;
      await _driver(HapticKind.heavy);
    }
  }
}
