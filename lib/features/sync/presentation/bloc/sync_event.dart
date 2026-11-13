import 'package:equatable/equatable.dart';

/// Splash/senkron ekranının olaylarının temel sınıfı.
sealed class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

/// Splash açıldı: eksik olanı indir (senkronluysa atla).
final class SyncStarted extends SyncEvent {
  const SyncStarted();
}

/// Bir hatadan sonra "Tekrar dene" dokunuldu: son kaydedilen sayfadan devam et.
final class SyncRetryRequested extends SyncEvent {
  const SyncRetryRequested();
}
