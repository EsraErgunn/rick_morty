import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../app/theme/card_style.dart';
import '../../../app/theme/colors.dart';
import '../../cards/game_card_data.dart';
import 'card_art.dart';

/// Bundled 2.5D art (`tools/images/cutout.py`): the character cut out of
/// its avatar, and the avatar itself as the (dimmed) background layer.
/// Only Rick has it for now.
abstract final class FeaturedArt {
  static const Set<int> _ids = {1};

  static bool has(int id) => _ids.contains(id);

  static String cutout(int id) => 'assets/featured/$id.webp';
  static String background(int id) => 'assets/featured/${id}_bg.webp';

  /// Where the cut-out is drawn, in card design units: as wide as
  /// [CardMetrics.featuredCutoutScale] × the art window, from
  /// [CardMetrics.featuredPopOut] above the window down to its bottom.
  /// The image is cropped to the top of the character, so the head always
  /// starts at the top of this rect.
  static Rect cutoutRect(Rect art) {
    final width = art.width * CardMetrics.featuredCutoutScale;
    return Rect.fromLTRB(
      art.center.dx - width / 2,
      art.top - CardMetrics.featuredPopOut,
      art.center.dx + width / 2,
      art.bottom,
    );
  }
}

/// No tilt (grids, battle): the layers rest.
const ValueListenable<Offset> _still = _Still();

class _Still implements ValueListenable<Offset> {
  const _Still();
  @override
  Offset get value => Offset.zero;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

/// Parallax shift of a layer for [tilt] (flutter_tilt `areaProgress`,
/// (1, 1) = top-left tilted down). A near layer moves toward the edge that
/// tilts away, a deep layer the other way.
Offset parallax(Offset tilt, double depth) => -tilt * depth;

/// Background of a 2.5D art window: the avatar, dimmed so the cut-out in
/// front reads as nearer, slightly oversized and shifted against the tilt. Falls back to the
/// network art if the asset is missing.
class FeaturedBackground extends StatelessWidget {
  const FeaturedBackground({
    required this.data,
    this.tilt,
    this.empty = false,
    super.key,
  });

  final GameCardData data;
  final ValueListenable<Offset>? tilt;

  /// The character is out of the card: the window dims.
  final bool empty;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      FeaturedArt.background(data.id),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          CardArt(url: data.imageUrl, name: data.name, rarity: data.rarity),
    );
    final dimmed = Opacity(
      opacity: empty
          ? CardMetrics.featuredEmptyArt
          : CardMetrics.featuredBackBrightness,
      child: image,
    );
    return ColoredBox(
      color: AppColors.ink,
      child: ValueListenableBuilder<Offset>(
        valueListenable: tilt ?? _still,
        builder: (context, t, child) => Transform.translate(
          offset: parallax(t, -CardMetrics.featuredParallaxBack),
          child: Transform.scale(
            scale: CardMetrics.featuredBackOverscan,
            child: child,
          ),
        ),
        child: dimmed,
      ),
    );
  }
}

/// The cut-out character, positioned by the caller at
/// [FeaturedArt.cutoutRect]. Clipped to [window] (the art window, local to
/// this rect) except at the top, so only the head can leave the window.
/// Moves with the tilt more than the background.
class FeaturedCutout extends StatelessWidget {
  const FeaturedCutout({
    required this.id,
    required this.window,
    this.tilt,
    super.key,
  });

  final int id;
  final Rect window;
  final ValueListenable<Offset>? tilt;

  @override
  Widget build(BuildContext context) => ClipRect(
    clipper: _OpenTopClip(window),
    child: ValueListenableBuilder<Offset>(
      valueListenable: tilt ?? _still,
      builder: (context, t, child) => Transform.translate(
        offset: parallax(t, CardMetrics.featuredParallaxFront),
        child: child,
      ),
      child: FeaturedCutoutImage(id: id),
    ),
  );
}

/// Just the cut-out image (also used by the battle reactions).
class FeaturedCutoutImage extends StatelessWidget {
  const FeaturedCutoutImage({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context) => Image.asset(
    FeaturedArt.cutout(id),
    fit: BoxFit.fitWidth,
    alignment: Alignment.topCenter,
    filterQuality: FilterQuality.medium,
    errorBuilder: (_, _, _) => const SizedBox.shrink(),
  );
}

/// Clips to [window] with the top left open for the head.
class _OpenTopClip extends CustomClipper<Rect> {
  const _OpenTopClip(this.window);

  final Rect window;

  static const double _open = 1000;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(window.left, -_open, window.right, window.bottom);

  @override
  bool shouldReclip(_OpenTopClip old) => old.window != window;
}
