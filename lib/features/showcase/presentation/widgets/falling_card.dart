import 'package:flutter/material.dart';

import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../core/cards/game_card_data.dart';
import '../../../../core/sensors/tilt_stream.dart';
import '../../../../core/widgets/game_card/game_card.dart';
import '../../../../core/widgets/game_card/holo_layer.dart';
import '../../../../core/widgets/game_card/tilting_game_card.dart';
import '../../../../core/widgets/shader_cache.dart';

/// Portaldan düşen, yere değince hafifçe basılan, eğimle hareket eden kart.
/// [drop] düşüşün ilerlemesidir (0..1); sahibi sayfadır.
class FallingCard extends StatelessWidget {
  const FallingCard({
    required this.card,
    required this.drop,
    required this.tiltStream,
    required this.shaders,
    super.key,
  });

  final GameCardData card;
  final Animation<double> drop;
  final TiltStream tiltStream;
  final ShaderCache shaders;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: drop,
    builder: (context, child) {
      final v = drop.value;
      final fall = AppMotion.fall.transform((v / 0.75).clamp(0.0, 1.0));
      final squash = v > 0.75 ? 1 - ((v - 0.75) / 0.25) : 0.0;
      return Opacity(
        opacity: (v * 3).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, -AppSizes.showcaseDropHeight * (1 - fall)),
          child: Transform.scale(
            scaleX: 1 + AppSizes.battleSquash * squash,
            scaleY: 1 - AppSizes.battleSquash * squash,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        ),
      );
    },
    child: SizedBox(
      width: AppSizes.showcaseCard,
      child: TiltingGameCard(
        tiltStream: tiltStream,
        builder: (context, tilt) => GameCard(
          data: card,
          tilt: tilt,
          holo: HoloLayer(rarity: card.rarity, tilt: tilt, shaders: shaders),
        ),
      ),
    ),
  );
}
