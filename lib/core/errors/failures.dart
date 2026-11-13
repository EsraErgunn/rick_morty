import 'package:equatable/equatable.dart';

/// Bir repository çağıranına ulaşan her hata. Repository'ler
/// `Either<Failure, T>` döndürür; hiçbir istisna arayüze geçmez.
sealed class Failure extends Equatable {
  const Failure(this.message);

  /// Loglar için geliştiriciye yönelik ayrıntı. Arayüz kendi l10n metnini gösterir.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Bağlantı yok, DNS hatası, TLS sorunu.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'network']);
}

/// Bağlanma, gönderme veya alma zaman aşımı (tekrar denemelerden sonra).
final class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'timeout']);
}

/// Tekrar denemelerden sonra HTTP 429 veya 5xx.
final class ServerFailure extends Failure {
  const ServerFailure(this.statusCode, [super.message = 'server']);

  final int statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

/// 429 dışındaki HTTP 4xx (asla tekrar denenmez).
final class ClientFailure extends Failure {
  const ClientFailure(this.statusCode, [super.message = 'client']);

  final int statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

/// Bir yanıt ya da kayıt beklenmeyen biçimdeydi.
final class ParseFailure extends Failure {
  const ParseFailure([super.message = 'parse']);
}

/// Yerel depolamaya okuma veya yazma başarısız oldu.
final class StorageFailure extends Failure {
  const StorageFailure([super.message = 'storage']);
}

/// Yukarıdakilerin kapsamadığı her şey.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'unexpected']);
}

/// Bir satın alma, oyuncunun sahip olduğundan fazla coin gerektiriyor (hiçbir şey değişmedi).
final class NotEnoughCoinsFailure extends Failure {
  const NotEnoughCoinsFailure(this.needed, this.balance)
    : super('not enough coins');

  final int needed;
  final int balance;

  @override
  List<Object?> get props => [message, needed, balance];
}

/// Destede zaten 3 kart var (SPEC varsayım 2); hiçbir şey değişmedi.
final class DeckFullFailure extends Failure {
  const DeckFullFailure() : super('deck full');
}

/// Kuralların izin vermediği bir savaş hamlesi (bayılmış kart, yanlış taraf,
/// sıra sende değil, savaş bitti). Hiçbir şey değişmedi.
final class InvalidMoveFailure extends Failure {
  const InvalidMoveFailure([super.message = 'invalid move']);
}
