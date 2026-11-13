import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/cards/game_card_data.dart';
import '../../../core/errors/failures.dart';

/// Sahip olunan bir kart.
final class CollectionEntry extends Equatable {
  const CollectionEntry({
    required this.card,
    required this.copies,
    required this.obtainedAt,
  });

  final GameCardData card;
  final int copies;
  final DateTime obtainedAt;

  @override
  List<Object?> get props => [card, copies, obtainedAt];
}

/// Koleksiyon, kart detayı ve deste ekranlarının veri kaynağı.
abstract interface class CollectionRepository {
  static const int deckSize = 3;

  List<CollectionEntry> entries();

  /// Bu repository'nin arkasındaki kayıtlı veriler her değiştiğinde tetiklenir.
  Stream<void> get changes;

  int get totalCharacters;

  /// Senkronlanmış herhangi bir karakter (kart laboratuvarı ve detay), sahip olunsun ya da olunmasın.
  GameCardData? card(int id);
  bool owns(int id);
  List<int> get deck;

  /// [id]'yi desteye ekler ya da zaten varsa çıkarır.
  /// Dolu bir desteye eklerken [DeckFullFailure] (hiçbir şey değişmez).
  Future<Either<Failure, List<int>>> toggleDeck(int id);
}
