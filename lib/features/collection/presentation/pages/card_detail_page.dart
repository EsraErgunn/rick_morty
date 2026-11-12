import 'package:flutter/material.dart';

import '../../../../app/theme/spacing.dart';
import '../../../../core/cards/game_card_data.dart';
import '../../../../core/sensors/tilt_stream.dart';
import '../../../../core/widgets/game_card/card_back.dart';
import '../../../../core/widgets/game_card/flip_card.dart';
import '../../../../core/widgets/game_card/game_card.dart';
import '../../../../core/widgets/game_card/holo_layer.dart';
import '../../../../core/widgets/game_card/shader_cache.dart';
import '../../../../core/widgets/game_card/tilting_game_card.dart';
import '../../../../l10n/app_localizations.dart';

/// Card detail (Week 1 placeholder, plan T20): one large card that tilts
/// with the phone or a drag and flips on tap. The collection feature
/// (Week 2/3) adds ownership, deck actions and the BlocListener for sound.
class CardDetailPage extends StatelessWidget {
  const CardDetailPage({
    required this.id,
    required this.data,
    required this.tiltStream,
    required this.shaders,
    super.key,
  });

  final int id;

  /// Null if the character is not in local storage.
  final GameCardData? data;
  final TiltStream tiltStream;
  final ShaderCache shaders;

  @override
  Widget build(BuildContext context) {
    final card = data;
    final title =
        card?.name ?? AppLocalizations.of(context).cardDetailTitle('$id');
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: card == null
              ? Text(title, style: Theme.of(context).textTheme.displayMedium)
              : Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: TiltingGameCard(
                    tiltStream: tiltStream,
                    builder: (context, tilt) => FlipCard(
                      front: GameCard(
                        data: card,
                        holo: HoloLayer(
                          rarity: card.rarity,
                          tilt: tilt,
                          shaders: shaders,
                        ),
                      ),
                      back: CardBack(facts: card),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
