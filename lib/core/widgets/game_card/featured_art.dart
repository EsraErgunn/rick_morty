import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../app/theme/card_style.dart';
import '../../../app/theme/colors.dart';
import '../../cards/game_card_data.dart';
import 'card_art.dart';

/// Paketlenmiş 2.5D görsel (`tools/images/cutout.py`): avatarından kesilmiş
/// karakter ve (karartılmış) arka plan katmanı olarak avatarın kendisi.
/// Şimdilik yalnızca Rick'te var.
abstract final class FeaturedArt {
  static const Set<int> _ids = {1};

  static bool has(int id) => _ids.contains(id);

  static String cutout(int id) => 'assets/featured/$id.webp';
  static String background(int id) => 'assets/featured/${id}_bg.webp';

  /// Kesilmiş görselin çizildiği yer, kart tasarım birimleri cinsinden: görsel
  /// penceresinin [CardMetrics.featuredCutoutScale] katı genişlikte, pencerenin
  /// [CardMetrics.featuredPopOut] üstünden altına kadar.
  /// Görsel karakterin tepesinden kırpılmıştır, böylece kafa her zaman
  /// bu dikdörtgenin üstünden başlar.
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

/// Eğim yok (ızgaralar, savaş): katmanlar durur.
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

/// [tilt] için bir katmanın paralaks kayması (flutter_tilt `areaProgress`,
/// (1, 1) = sol üst aşağı eğik). Yakın katman uzaklaşan kenara doğru,
/// derin katman ters yöne hareket eder.
Offset parallax(Offset tilt, double depth) => -tilt * depth;

/// 2.5D görsel penceresinin arka planı: öndeki kesilmiş görsel daha yakın görünsün diye
/// karartılmış avatar; biraz büyük çizilir ve eğime karşı kaydırılır. Görsel dosyası
/// yoksa ağdaki görsele geri döner.
class FeaturedBackground extends StatelessWidget {
  const FeaturedBackground({
    required this.data,
    this.tilt,
    this.empty = false,
    super.key,
  });

  final GameCardData data;
  final ValueListenable<Offset>? tilt;

  /// Karakter kartın dışında: pencere kararır.
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

/// Kesilmiş karakter; çağıran onu [FeaturedArt.cutoutRect] konumuna
/// yerleştirir. Üst kısım hariç [window] alanına (görsel penceresi, bu dikdörtgene
/// göre) kırpılır, böylece yalnızca kafa pencereden çıkabilir.
/// Eğimle arka plandan daha fazla hareket eder.
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

/// Yalnızca kesilmiş görsel (savaş tepkilerinde de kullanılır).
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

/// Kafa için üstü açık bırakılarak [window] alanına kırpar.
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
