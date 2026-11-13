import 'package:equatable/equatable.dart';

import '../../../core/cards/game_card_data.dart';

/// Albümün tek bir bölüm sayfası [GM §9]: `owned / total` karakter.
final class AlbumEpisode extends Equatable {
  const AlbumEpisode({
    required this.id,
    required this.code,
    required this.name,
    required this.owned,
    required this.total,
  });

  final int id;

  /// `S01E01`.
  final String code;
  final String name;
  final int owned;
  final int total;

  /// Koddan sezon numarası (`S03E07` → 3); kod tuhafsa 0.
  int get season =>
      int.tryParse(code.length >= 3 ? code.substring(1, 3) : '') ?? 0;

  bool get complete => total > 0 && owned >= total;

  @override
  List<Object?> get props => [id, code, name, owned, total];
}

/// Bir bölüm sayfasındaki tek karakter: sahip olunduysa görsel, değilse siluet.
final class AlbumMember extends Equatable {
  const AlbumMember({required this.card, required this.owned});

  final GameCardData card;
  final bool owned;

  @override
  List<Object?> get props => [card, owned];
}

/// Az önce ödenen bir albüm ödülü ([GM §8]: bölüm başına bir kez).
final class AlbumReward extends Equatable {
  const AlbumReward({required this.code, required this.coins});

  final String code;
  final int coins;

  @override
  List<Object?> get props => [code, coins];
}

/// Albüm ekranlarının veri kaynağı: bölümler, karakterler ve sayfa ödülleri.
abstract interface class AlbumRepository {
  /// Koda göre sıralanmış tüm bölümler (önce `S01E01`).
  List<AlbumEpisode> episodes();

  AlbumEpisode? episode(int id);

  /// API sırasıyla bölümün karakterleri.
  List<AlbumMember> members(int episodeId);

  /// Henüz ödenmemiş her tamamlanmış bölümün ödülünü öder ve
  /// ödenenleri döndürür (hiçbir şey yoksa boş). Bir bölümü asla iki kez ödemez.
  Future<List<AlbumReward>> claimCompleted();

  /// Kartlar, coin'ler veya ödenen albümler her değiştiğinde tetiklenir.
  Stream<void> get changes;
}
