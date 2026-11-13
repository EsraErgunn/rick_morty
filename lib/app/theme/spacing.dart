import 'package:flutter/painting.dart';

/// 4 dp ızgarasında boşluklar (SPEC §5.4).
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Yatay ekran kenar boşluğu.
  static const double gutter = md;
}

/// Hiyerarşiye göre köşe yarıçapı, tek bir değer değil (SPEC §5.4).
abstract final class AppRadius {
  static const double card = 14;
  static const double button = 12;

  /// Alt sayfaların üst köşeleri.
  static const double sheet = 24;

  /// Herhangi bir çipi tam hap şekline getirecek kadar büyük.
  static const double pill = 999;

  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius buttonAll = BorderRadius.all(
    Radius.circular(button),
  );
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}

/// Mürekkep dış çizgi kalınlıkları (SPEC §5.4). Dış çizgiler her zaman `AppColors.ink`.
abstract final class AppOutline {
  /// Kartlar ve butonlar.
  static const double thick = 2.5;

  /// Çipler.
  static const double thin = 2;

  /// En fazla elle çizilmiş titreme; yalnızca kartlarda ve ana butonda çizilir.
  static const double wobble = 0.6;
}

/// Sert kaydırılmış gölge, bulanıklık yok (SPEC §5.4). Yalnızca etkileşimli yükseltilmiş öğelerde.
abstract final class AppDepth {
  /// Gölge sağ-aşağı kaydırılır; basılan öğe aynı miktarda hareket eder.
  static const double shadowOffset = 4;

  static const Offset shadow = Offset(shadowOffset, shadowOffset);
}

/// Sabit bileşen boyutları.
abstract final class AppSizes {
  /// Splash ekranındaki portal (dar ekranlara sığmak için küçülür).
  static const double splashPortal = 220;

  /// İlerleme çubuklarının yüksekliği.
  static const double progressBar = 12;

  /// Ortalanmış içerik bloklarının (yazı, çubuk, buton) en fazla genişliği.
  static const double contentMaxWidth = 320;

  /// Portal ekranındaki portal (küçük ekranlarda küçülür).
  static const double portalHero = 300;

  /// Açılış sahnesindeki kart genişliği.
  static const double revealCard = 200;

  /// Portal patlamasındaki ekran sarsıntısı genliği (SPEC §4.3).
  static const double screenShake = 6;

  /// Coin sayacı sarsıntı genliği.
  static const double coinShake = 8;

  /// İnen kartın havada hafif sallanması.
  static const double hoverBob = 2;

  /// İkon boyutları.
  /// Savaş: seçili kartın kalkması, saldırı atılması, hasar sayısının yükselmesi,
  /// bayılma düşüşü, HP çubuğu yüksekliği.
  static const double battleLift = 8;
  static const double battleLunge = 28;
  static const double battleNumberRise = 40;
  static const double battleFaintDrop = 12;
  static const double battleFaintTilt = 0.12;

  /// Savaş karakter animasyonu (SPEC §4.7, teslim cilası).
  static const double battleIdleFloat = 5;
  static const double gridFloat = 3;
  static const double battleWindUp = 14;
  static const double battleDash = 84;
  static const double battleHop = 22;
  static const double battleLungeSpin = 0.14;
  static const double battleSquash = 0.16;
  static const double battleHitShake = 10;
  static const double battleCritShake = 20;
  static const double battleKnockTilt = 0.2;
  static const double battleVictoryHop = 28;
  static const double battleParticle = 7;
  static const double battleParticleSpread = 56;
  static const double battleStageShake = 7;
  static const double battleStageCritShake = 14;

  /// Rick'in savaş tepkisi (kartın tasarım birimleri cinsinden).
  static const double rickLeap = 110;
  static const double rickLeapScale = 0.4;
  static const double rickSink = 40;
  static const double rickSquash = 0.25;
  static const double rickTopple = 1.2;
  static const double rickToppleShift = 24;
  static const double rickBubbleWidth = 150;
  static const double rickBubbleTail = 10;
  static const double confettiSize = 6;
  static const double confettiSpread = 150;
  static const double confettiFall = 180;

  /// İlk açılış tanıtımı (onboarding).
  static const double onboardingArt = 260;
  static const double onboardingPortal = 180;
  static const double onboardingCard = 96;
  static const double onboardingHeroCard = 140;
  static const double onboardingFanTilt = 0.18;
  static const double onboardingTypeDisc = 64;
  static const double onboardingDot = 8;
  static const double onboardingDotActive = 24;
  static const double onboardingWiggle = 0.25;

  static const double hpBar = 8;

  /// En küçük dokunma alanı (Material / erişilebilirlik).
  static const double minTouch = 48;

  static const double iconSmall = 20;
  static const double iconLarge = 40;
}
