import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/card_style.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../game/rarity.dart';

/// [url] için görseli kurar; widget testlerinde değiştirilir (orada ağ ve
/// platform önbelleği yok).
typedef ArtBuilder = Widget Function(String url, String name);

/// Karakter görseli: yüklenirken yer tutuculu `CachedNetworkImage`;
/// görsel yüklenemezse nadirlik renginde ismin baş harfi
/// (CLAUDE.md görsel kuralı), böylece bir kart asla boş görünmez.
class CardArt extends StatelessWidget {
  const CardArt({
    required this.url,
    required this.name,
    required this.rarity,
    super.key,
  });

  final String url;
  final String name;
  final Rarity rarity;

  /// Test kancası: ayarlıysa ağ görseli yerine kullanılır.
  @visibleForTesting
  static ArtBuilder? debugArtBuilder;

  @override
  Widget build(BuildContext context) {
    final override = debugArtBuilder;
    if (override != null) return override(url, name);
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => const ColoredBox(color: AppColors.voidRaised),
      errorWidget: (_, _, _) => InitialArt(name: name, rarity: rarity),
    );
  }
}

/// Çevrimdışı / eksik görsel: mürekkep dış çizgili, nadirlik renginde bir
/// dairede ismin ilk harfi ve altında isim.
class InitialArt extends StatelessWidget {
  const InitialArt({required this.name, required this.rarity, super.key});

  final String name;
  final Rarity rarity;

  static const double _discShare = 0.62;

  static String initialOf(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = RarityStyle.of(rarity).color;
    return ColoredBox(
      key: const ValueKey('art-initial'),
      color: AppColors.voidRaised,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: FractionallySizedBox(
                heightFactor: _discShare,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.ink,
                        width: AppOutline.thick,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: FittedBox(
                        child: Text(
                          initialOf(name),
                          style: AppTypography.display.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xxs),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption,
            ),
          ),
        ],
      ),
    );
  }
}
