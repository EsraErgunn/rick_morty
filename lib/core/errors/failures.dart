import 'package:equatable/equatable.dart';

/// Every error that reaches a repository caller. Repositories return
/// `Either<Failure, T>`; no exception crosses into the UI.
sealed class Failure extends Equatable {
  const Failure(this.message);

  /// Developer-facing detail for logs. The UI shows its own l10n text.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// No connection, DNS failure, TLS problem.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'network']);
}

/// Connect, send or receive timeout (after retries).
final class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'timeout']);
}

/// HTTP 429 or 5xx after retries.
final class ServerFailure extends Failure {
  const ServerFailure(this.statusCode, [super.message = 'server']);

  final int statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

/// HTTP 4xx other than 429 (never retried).
final class ClientFailure extends Failure {
  const ClientFailure(this.statusCode, [super.message = 'client']);

  final int statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

/// A response or stored record had an unexpected shape.
final class ParseFailure extends Failure {
  const ParseFailure([super.message = 'parse']);
}

/// Reading or writing local storage failed.
final class StorageFailure extends Failure {
  const StorageFailure([super.message = 'storage']);
}

/// Anything not covered above.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'unexpected']);
}

/// A purchase needs more coins than the player has (nothing changed).
final class NotEnoughCoinsFailure extends Failure {
  const NotEnoughCoinsFailure(this.needed, this.balance)
    : super('not enough coins');

  final int needed;
  final int balance;

  @override
  List<Object?> get props => [message, needed, balance];
}
