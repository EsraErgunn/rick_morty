import 'package:equatable/equatable.dart';

/// Portal ekranının olaylarının temel sınıfı.
sealed class PortalEvent extends Equatable {
  const PortalEvent();

  @override
  List<Object?> get props => [];
}

/// Sayfa açıldı: coin'leri ve ipucu işaretini yükle.
final class PortalStarted extends PortalEvent {
  const PortalStarted();
}

/// Telefon sallandı (ShakeDetector).
final class PortalShaken extends PortalEvent {
  const PortalShaken();
}

/// "Portalı aç" dokunuldu (emülatörler ve erişilebilirlik için yedek).
final class PortalOpenRequested extends PortalEvent {
  const PortalOpenRequested();
}

/// Açılış sahnesi bitti (kart çevrildi, efektler tamam).
final class RevealFinished extends PortalEvent {
  const RevealFinished();
}

/// "Tekrar aç" / sonuçtan çıkış: boştaki portala geri dön.
final class PortalReset extends PortalEvent {
  const PortalReset();
}
