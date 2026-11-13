import 'dart:math';

import 'rarity.dart';

/// Tek bir portal seçiminin sonucu [GM §7].
final class PortalPick {
  const PortalPick({
    required this.rolled,
    required this.rarity,
    required this.characterId,
    required this.isDuplicate,
  });

  /// Çekilişten gelen nadirlik (ya da demo zorlaması).
  final Rarity rolled;

  /// Gerçekte verilen karakterin nadirliği (aşağı kayma sonrası daha düşük).
  final Rarity rarity;
  final int characterId;
  final bool isDuplicate;

  @override
  String toString() =>
      'PortalPick(rolled: ${rolled.name}, rarity: ${rarity.name}, '
      'id: $characterId, duplicate: $isDuplicate)';
}

/// Portal çekilişi [GM §7, §7.1–§7.3]. Saf Dart; `Random` her zaman parametre olarak verilir.
abstract final class PortalRoll {
  /// Nadirlik başına şans [GM §7].
  static const Map<Rarity, double> chances = {
    Rarity.common: 0.60,
    Rarity.rare: 0.28,
    Rarity.epic: 0.10,
    Rarity.legendary: 0.02,
  };

  /// Asla tekrar kart vermeyen portallar [GM §7.1].
  static const int guaranteedNewPortals = 3;

  /// [chances] ile bir nadirlik çeker (bir `nextDouble`).
  static Rarity rollRarity(Random random) {
    final x = random.nextDouble();
    var edge = 0.0;
    for (final rarity in Rarity.values) {
      edge += chances[rarity]!;
      if (x < edge) return rarity;
    }
    return Rarity.common; // 1.0'da kayan nokta yuvarlaması
  }

  /// Tek bir portal için karakteri seçer.
  ///
  /// - [forceLegendary] (demo, [GM §7.2]) nadirlik çekilişini atlar.
  /// - [portalsOpened] < 3 iken yalnızca sahip olunmayan karakterler verilir; biri
  ///   tükenince bir nadirlik aşağı kayılır [GM §7.1, §7.3]; oyuncu tüm
  ///   karakterlere sahipse çekilen nadirlikten normal bir tekrar verilir.
  /// - Sonraki portallar çekilen nadirlikten eşit şansla seçer (tekrar
  ///   olabilir). Boş bir nadirlik havuzu önce aşağı, sonra yukarı kayar.
  static PortalPick pick({
    required Map<Rarity, List<int>> pool,
    required Set<int> owned,
    required int portalsOpened,
    required bool forceLegendary,
    required Random random,
  }) {
    final rolled = forceLegendary ? Rarity.legendary : rollRarity(random);

    if (portalsOpened < guaranteedNewPortals) {
      for (final rarity in _stepDown(rolled)) {
        final fresh = [
          for (final id in pool[rarity] ?? const <int>[])
            if (!owned.contains(id)) id,
        ];
        if (fresh.isNotEmpty) {
          return PortalPick(
            rolled: rolled,
            rarity: rarity,
            characterId: fresh[random.nextInt(fresh.length)],
            isDuplicate: false,
          );
        }
      }
    }

    final rarity = _firstNonEmpty(pool, rolled);
    final ids = pool[rarity]!;
    final id = ids[random.nextInt(ids.length)];
    return PortalPick(
      rolled: rolled,
      rarity: rarity,
      characterId: id,
      isDuplicate: owned.contains(id),
    );
  }

  /// [from], sonra her daha düşük nadirlik (efsanevi → epik → nadir → sıradan).
  static Iterable<Rarity> _stepDown(Rarity from) =>
      Rarity.values.reversed.where((r) => r.index <= from.index);

  static Rarity _firstNonEmpty(Map<Rarity, List<int>> pool, Rarity from) {
    final order = [
      ..._stepDown(from),
      ...Rarity.values.where((r) => r.index > from.index),
    ];
    for (final r in order) {
      if ((pool[r] ?? const []).isNotEmpty) return r;
    }
    throw StateError('portal pool is empty');
  }
}
