import 'package:equatable/equatable.dart';

/// Tanıtım ekranının olaylarının temel sınıfı.
sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

/// Tanıtım açıldı: vitrin kartlarını yükle.
final class OnboardingStarted extends OnboardingEvent {
  const OnboardingStarted();
}

/// Kullanıcı [page] sayfasına kaydırdı (ya da bir noktaya dokundu).
final class OnboardingPageChanged extends OnboardingEvent {
  const OnboardingPageChanged(this.page);

  final int page;

  @override
  List<Object?> get props => [page];
}

/// "Geç" ya da "Başla": tanıtımı hatırla ve çık.
final class OnboardingFinished extends OnboardingEvent {
  const OnboardingFinished();
}
