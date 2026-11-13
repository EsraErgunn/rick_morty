import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:portalcards/core/audio/audio_assets.dart';
import 'package:portalcards/core/audio/audio_backend.dart';
import 'package:portalcards/core/audio/audio_service.dart';
import 'package:portalcards/core/errors/failures.dart';
import 'package:portalcards/core/game/economy.dart';
import 'package:portalcards/core/haptics/haptics_service.dart';
import 'package:portalcards/features/portal/domain/portal_repository.dart';
import 'package:portalcards/features/portal/presentation/portal_feedback.dart';

import '../../helpers/cards.dart';

/// Senaryolu sonuçlar veren repository.
class FakePortalRepository implements PortalRepository {
  FakePortalRepository({
    this.coins = 300,
    this.shakeHintSeen = false,
    List<Either<Failure, PortalResult>>? results,
    this.hold = false,
  }) : results = results ?? [right(resultFor(1))];

  @override
  int coins;
  @override
  bool shakeHintSeen;
  final List<Either<Failure, PortalResult>> results;
  final bool hold;
  int opened = 0;
  Completer<void> gate = Completer<void>();

  @override
  Future<Either<Failure, PortalResult>> open() async {
    final r = results[opened < results.length ? opened : results.length - 1];
    opened++;
    if (hold) await gate.future;
    r.match((_) {}, (ok) {
      coins = ok.coinsAfter;
      shakeHintSeen = true;
    });
    return r;
  }
}

PortalResult resultFor(
  int id, {
  bool duplicate = false,
  int coinsBefore = 300,
}) {
  final card = fixtureCard(id);
  final refund = duplicate ? Economy.duplicateCoins(card.rarity) : 0;
  return PortalResult(
    card: card,
    rolled: card.rarity,
    isDuplicate: duplicate,
    duplicateCoins: refund,
    coinsBefore: coinsBefore,
    coinsAfter: coinsBefore - EconomyRules.portalCost + refund,
  );
}

/// Her sesi ve titreşimi kaydeder.
class RecordingBackend implements AudioBackend {
  final List<Sfx> played = [];

  @override
  Future<void> preload(Iterable<Sfx> sounds) async {}

  @override
  Future<void> playSfx(Sfx sound, double volume) async => played.add(sound);

  @override
  Future<MusicHandle> startMusic(Music track, double volume) async =>
      _SilentHandle();
}

class _SilentHandle implements MusicHandle {
  @override
  Future<void> get completed => Completer<void>().future;
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> stop() async {}
}

class RecordingFeedback {
  RecordingFeedback() {
    feedback = PortalFeedback(
      audio: AudioService(backend: backend),
      haptics: HapticsService(driver: (k) async => haptics.add(k)),
    );
  }

  final RecordingBackend backend = RecordingBackend();
  final List<HapticKind> haptics = [];
  late final PortalFeedback feedback;

  List<Sfx> get sounds => backend.played;
}
