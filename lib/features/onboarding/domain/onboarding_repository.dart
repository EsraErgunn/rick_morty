import 'package:fpdart/fpdart.dart';

import '../../../core/cards/game_card_data.dart';
import '../../../core/errors/failures.dart';

/// İlk açılış tanıtımı: görülüp görülmediği ve içinde gösterilecek gerçek kartlar.
abstract interface class OnboardingRepository {
  /// Tanıtım bir kez gösterildi (ya da geçildi).
  bool get seen;

  /// Sıradandan efsaneviye senkronlanmış kartlar (bulunduğu kadarıyla nadirlik başına bir),
  /// "kartlarını topla" sayfası için. Hiçbir şey senkronlanmadıysa boş.
  List<GameCardData> showcaseCards();

  Future<Either<Failure, Unit>> markSeen();
}
