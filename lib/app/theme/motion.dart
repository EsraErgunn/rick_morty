import 'package:flutter/animation.dart';

/// Animasyon token'ları (animasyon kuralları, `.claude/rules/animation-audio.md`).
///
/// Widget'lar asla ham süre veya eğri kullanmaz; buradan okurlar.
abstract final class AppMotion {
  /// Dokunuşlar, anahtarlar, küçük durum değişiklikleri.
  static const Duration fast = Duration(milliseconds: 150);

  /// Hareketler, kart çevirme, ekran düzeyindeki geçişler.
  static const Duration normal = Duration(milliseconds: 300);

  /// Ortaya çıkışlar ve vurgu.
  static const Duration slow = Duration(milliseconds: 600);

  /// Portalın açılması, efsanevi açılış. En az bu kadar; diziler daha uzun sürebilir.
  static const Duration cinematic = Duration(milliseconds: 1500);

  /// Yükleyici yalnızca yükleme bundan uzun sürerse gösterilir (titreme olmasın).
  static const Duration loaderShowDelay = Duration(milliseconds: 300);

  /// Bir kez gösterildiyse yükleyici en az bu kadar kalır.
  static const Duration loaderMinVisible = slow;

  /// Bekleyen portalın bir tam dönüşü.
  /// Başarılı bir senkrondan sonra splash'in yükleyicinin kapanmasını bekleyeceği en uzun süre
  /// (en az görünme + kapanma + pay); sonra yine de geçiş yapar.
  static const Duration splashExitLimit = Duration(milliseconds: 1500);

  /// Bu süre içinde yüklenip ısınmayan bir shader
  /// statik çizimine geri döner.
  static const Duration shaderLoadLimit = Duration(seconds: 3);

  static const Duration portalSpin = Duration(milliseconds: 3200);

  /// Sallama ipucu: bir salınım; üç salınım, sonra [hintPause] (SPEC §4.3).
  static const Duration hintSwing = normal;
  static const Duration hintPause = Duration(milliseconds: 1200);

  /// Portal için coin yetmediğinde coin sayacının sallanması (3 tur).
  static const Duration coinShake = normal;

  /// Açılış sahnesi (SPEC §4.3, D7).
  static const Duration revealCharge = slow;
  static const Duration revealBurst = fast;
  static const Duration revealEmerge = slow;
  static const Duration revealEmergeLegendary = cinematic;
  static const Duration revealFall = normal;
  static const Duration revealSquash = fast;
  static const Duration revealHintDelay = Duration(milliseconds: 1500);
  static const Duration revealAutoFlip = Duration(milliseconds: 4000);
  static const Duration revealHover = Duration(milliseconds: 1200);

  /// Azaltılmış hareket: tüm açılış tek bir geçişli solmadır.
  static const Duration revealReduced = slow;

  /// Menü öğeleri birbiri ardına girer (SPEC §4.2).
  static const Duration stagger = Duration(milliseconds: 40);

  /// Boş koleksiyondaki eylem çağrısı nefes alır (ölçek 1.0'dan 1.04'e).
  static const Duration breathe = Duration(milliseconds: 1200);
  static const double breatheScale = 1.04;

  /// Demo kilidi açma: sürüm yazısına dokunuşlar bu süre içinde olmalı (D2).
  static const Duration demoTapWindow = Duration(seconds: 3);

  /// Yeni öğelerin belirerek gelmesi.
  /// Savaş (SPEC §4.7): kartlar bu aralıklarla dağıtılır.
  static const Duration battleDealStagger = Duration(milliseconds: 80);

  /// Tekrar oynatılan her olaydan sonraki boşluk; bir tur en fazla 1,6 sn sürer.
  static const Duration battleGap = fast;

  /// Vuruş, kaçma veya bayılma tekrar oynatmayı bu kadar bekletir (`normal` + boşluk).
  static const Duration battleHit = Duration(milliseconds: 450);

  /// Azaltılmış hareket: her tekrar adımı kısa bir solmadır.
  static const Duration battleReduced = fast;

  /// 2× anahtarı tekrar sürelerini buna böler.
  static const int battleFastFactor = 2;

  /// Saldırı: hazırlık, sıçrama, çarpma, dönüş. Vuruş olayı
  /// [battleAttackImpact] anında, saldıran hâlâ hedefin üstündeyken başlar.
  static const Duration battleAttack = Duration(milliseconds: 700);
  static const Duration battleAttackImpact = Duration(milliseconds: 400);

  /// Kritik / süper etkili vuruş: daha büyük sarsıntı ve yanıp sönen ışık.
  static const Duration battleHeavyHit = slow;

  /// Bayılma: kart döner, küçülür ve küçük bir portala çekilir.
  static const Duration battleFaint = Duration(milliseconds: 900);

  /// Zafer: kazananlar birbiri ardına zıplar.
  static const Duration battleVictory = Duration(milliseconds: 1200);
  static const Duration battleVictoryStagger = Duration(milliseconds: 160);

  /// Rick'in 2.5D zafer / yenilgi tepkisi (kesilmiş görsel karttan çıkar). Savaş
  /// sonu, tepki bitebilsin diye tekrar oynatmayı bu kadar bekletir.
  static const Duration battleRickReaction = Duration(milliseconds: 2000);

  /// Tanıtım: bir sayfa görselinin bir döngüsü (sallama kıpırtısı, tip döngüsü,
  /// savaş çarpışması).
  static const Duration onboardingLoop = Duration(milliseconds: 2400);

  /// Savaş kartının boşta süzülmesi (bir aşağı-yukarı döngü); fazlar slota göre değişir.
  static const Duration battleIdle = Duration(milliseconds: 2400);

  /// Koleksiyon ve deste ızgaralarındaki kartların hafif süzülmesi.
  static const Duration gridFloat = Duration(milliseconds: 3200);

  static const Curve popIn = Curves.easeOutBack;

  /// Konumlar arası hareket, kart çevirme.
  static const Curve move = Curves.easeInOutCubic;

  /// Ödüller (coin, zafer).
  static const Curve reward = Curves.elasticOut;

  /// Yerçekimiyle düşüş (karesel hızlanan giriş).
  static const Curve fall = Curves.easeInQuad;

  /// Portalın derinliğinden çıkan bir şey.
  static const Curve emerge = Curves.easeOutCubic;

  /// 3D dönüşler için perspektif değeri: `Matrix4..setEntry(3, 2, perspective)`.
  static const double perspective = 0.001;
}
