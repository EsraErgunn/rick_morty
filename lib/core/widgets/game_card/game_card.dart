import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../app/theme/card_style.dart';
import '../../../app/theme/spacing.dart';
import '../../cards/game_card_data.dart';
import 'card_front.dart';
import 'rarity_frame_painter.dart';

/// 5:7 bir kart. [CardMetrics] tasarım boyutunda yerleştirilir ve aldığı
/// alana ölçeklenir, böylece ızgarada ve detay sayfasında aynı görünür.
class GameCard extends StatelessWidget {
  const GameCard({
    required this.data,
    this.holo,
    this.hideArt = false,
    this.tilt,
    this.characterOut = false,
    super.key,
  });

  /// 2.5D paralaks için kart eğimi (bkz. [CardFront.tilt]).
  final ValueListenable<Offset>? tilt;

  /// 2.5D karakter karttan çıktı (bkz. [CardFront.characterOut]).
  final bool characterOut;

  final GameCardData data;

  /// Boş görsel penceresi (öne çıkan giriş).
  final bool hideArt;

  /// Yüzün üstüne çizilen, kart şekline kırpılan isteğe bağlı folyo
  /// (bir `HoloLayer`).
  final Widget? holo;

  @override
  Widget build(BuildContext context) {
    final overlay = holo;
    return CardSizer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CardFront(
              data: data,
              hideArt: hideArt,
              tilt: tilt,
              characterOut: characterOut,
            ),
          ),
          if (overlay != null)
            Positioned.fill(
              child: ClipPath(
                clipper: _CardClipper(RarityStyle.of(data.rarity).notch),
                child: overlay,
              ),
            ),
        ],
      ),
    );
  }
}

class _CardClipper extends CustomClipper<Path> {
  const _CardClipper(this.notch);

  final double notch;

  @override
  Path getClip(Size size) => cardShape(
    (Offset.zero & size).deflate(AppOutline.thick / 2),
    notch: notch,
  );

  @override
  bool shouldReclip(_CardClipper old) => old.notch != notch;
}

/// Tasarım boyutundaki kart yüzünü mevcut alana ölçekler (5:7).
class CardSizer extends StatelessWidget {
  const CardSizer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: CardMetrics.aspect,
    child: FittedBox(
      child: SizedBox(
        width: CardMetrics.designWidth,
        height: CardMetrics.designHeight,
        child: child,
      ),
    ),
  );
}
