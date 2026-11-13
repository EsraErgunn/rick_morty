import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../core/cards/game_card_data.dart';
import '../../../../core/sensors/tilt_stream.dart';
import '../../../../core/widgets/game_card/game_card.dart';
import '../../../../core/widgets/game_card/holo_layer.dart';
import '../../../../core/widgets/game_card/tilting_game_card.dart';
import '../../../../core/widgets/shader_cache.dart';

/// Sayfa 2: yelpaze gibi açılmış nadirlik merdiveni (sıradan → efsanevi) ve
/// önde en nadir kart; telefonla eğilir ve holo parlar.
class CardsSlideArt extends StatelessWidget {
  const CardsSlideArt({
    required this.cards,
    required this.tiltStream,
    required this.shaders,
    super.key,
  });

  /// Sıradandan efsaneviye; boş olabilir (hiçbir şey senkronlanmadı).
  final List<GameCardData> cards;
  final TiltStream tiltStream;
  final ShaderCache shaders;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const Icon(
        Icons.style,
        size: AppSizes.onboardingPortal,
        color: AppColors.portal,
      );
    }
    final hero = cards.last;
    final fan = cards.take(cards.length - 1).toList();
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        for (var i = 0; i < fan.length; i++)
          Align(
            alignment: Alignment(
              fan.length == 1 ? 0 : -1 + 2 * i / (fan.length - 1),
              0.6,
            ),
            child: Transform.rotate(
              angle:
                  AppSizes.onboardingFanTilt *
                  (fan.length == 1 ? 0 : -1 + 2 * i / (fan.length - 1)),
              child: SizedBox(
                width: AppSizes.onboardingCard,
                child: GameCard(data: fan[i]),
              ),
            ),
          ),
        Align(
          alignment: const Alignment(0, -0.4),
          child: SizedBox(
            width: AppSizes.onboardingHeroCard,
            child: TiltingGameCard(
              tiltStream: tiltStream,
              builder: (context, tilt) => GameCard(
                data: hero,
                tilt: tilt,
                holo: HoloLayer(
                  rarity: hero.rarity,
                  tilt: tilt,
                  shaders: shaders,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
