import 'package:fpdart/fpdart.dart';

import '../../../core/cards/card_factory.dart';
import '../../../core/cards/game_card_data.dart';
import '../../../core/errors/failures.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/storage/api_data_store.dart';
import '../../../core/storage/player_store.dart';
import '../domain/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl({
    required this._player,
    required this._apiData,
  });

  final PlayerStore _player;
  final ApiDataStore _apiData;

  /// Known characters across the rarities (the card lab fixtures); Rick
  /// last, so the legendary card is his 2.5D one.
  static const List<int> _candidates = [309, 86, 82, 71, 63, 23, 2, 1];

  @override
  bool get seen => _player.state.onboardingSeen;

  @override
  List<GameCardData> showcaseCards() {
    try {
      final byRarity = <Object, GameCardData>{};
      for (final id in _candidates) {
        final c = _apiData.character(id);
        if (c == null) continue;
        final card = CardFactory.fromCharacter(c);
        byRarity[card.rarity] = card;
      }
      return byRarity.values.toList()
        ..sort((a, b) => a.rarity.index.compareTo(b.rarity.index));
    } on Object catch (e, st) {
      AppLogger.error('onboarding showcase failed', e, st);
      return const [];
    }
  }

  @override
  Future<Either<Failure, Unit>> markSeen() async {
    try {
      await _player.update((s) => s.copyWith(onboardingSeen: true));
      return right(unit);
    } on Object catch (e, st) {
      AppLogger.error('onboarding write failed', e, st);
      return left(StorageFailure(e.runtimeType.toString()));
    }
  }
}
