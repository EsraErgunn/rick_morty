import 'package:flutter/painting.dart';

/// SPEC §5.2'deki renk token'ları ("Boşlukta çizgi film mürekkebi").
///
/// Ölçülen WCAG kontrast oranları SPEC §5.2'de kayıtlıdır ve
/// `test/app/theme/contrast_test.dart` ile kontrol edilir. Renkli zemin (portal,
/// uyarı, tehlike, nadirlik çerçeveleri) üzerindeki yazı [paper] değil, her zaman [ink] kullanır.
abstract final class AppColors {
  /// SPEC token'ı `void` (yeniden adlandırıldı: `void` bir Dart anahtar kelimesi).
  /// Uygulama arka planı: derin uzay çivit mavisi.
  static const Color voidBase = Color(0xFF15112B);

  /// Yüzeyler: paneller, slotlar, alt sayfalar, kart gövdesi.
  static const Color voidRaised = Color(0xFF231B45);

  /// Dış çizgiler ve sert gölgeler; renkli zeminler üzerindeki yazı.
  static const Color ink = Color(0xFF0B0918);

  /// [voidBase] üzerindeki ana yazı, kart isim plakaları.
  static const Color paper = Color(0xFFF2ECDF);

  /// İkincil yazı.
  static const Color paperMuted = Color(0xFFA9A3BF);

  /// Tek vurgu rengi: portal, ana eylem, seçim, ilerleme.
  static const Color portal = Color(0xFF8FE04A);

  /// Portal çekirdeği vurgusu, odak halkası.
  static const Color portalHot = Color(0xFFD4FF7A);

  /// Efsanevi portal, yıkıcı eylemler, düşük HP.
  static const Color danger = Color(0xFFFF5A4E);

  /// %50 ve altındaki HP. Turuncu, [rarityLegendary] altınından ayrı tutulur.
  static const Color warn = Color(0xFFFF9F43);

  /// Nadirlik çerçeve renkleri [GM §2]. Anlamsal: yalnızca nadirlik anlamına gelir.
  static const Color rarityCommon = Color(0xFF9AA5B1);
  static const Color rarityRare = Color(0xFF3FA9F5);
  static const Color rarityEpic = Color(0xFFA55EEA);
  static const Color rarityLegendary = Color(0xFFF7B731);
}
