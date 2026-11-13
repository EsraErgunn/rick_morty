import 'package:fpdart/fpdart.dart';

import '../../../core/cards/game_card_data.dart';
import '../../../core/errors/failures.dart';

/// First-launch intro: whether it was seen, and real cards to show in it.
abstract interface class OnboardingRepository {
  /// The intro was shown (or skipped) once.
  bool get seen;

  /// Synced cards from common to legendary (one per rarity, as found), for
  /// the "collect your cards" page. Empty if nothing is synced.
  List<GameCardData> showcaseCards();

  Future<Either<Failure, Unit>> markSeen();
}
