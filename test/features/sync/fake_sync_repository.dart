import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:portalcards/core/errors/failures.dart';
import 'package:portalcards/features/sync/domain/sync_repository.dart';

/// Bloc ve widget testleri için senaryolanabilir [SyncRepository].
class FakeSyncRepository implements SyncRepository {
  FakeSyncRepository({
    this.progress = const [],
    List<Either<Failure, Unit>>? results,
    this.hold = false,
  }) : results = results ?? [right(unit)];

  /// Her çalıştırmada sırayla bildirilir.
  final List<SyncProgress> progress;

  /// Çalıştırma başına bir; sonuncusu tekrar eder.
  final List<Either<Failure, Unit>> results;

  /// True ise bir çalıştırma bitmeden önce [release]'i bekler.
  final bool hold;
  Completer<void> _gate = Completer<void>();

  int runs = 0;

  void release() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  bool get isSynced => false;

  @override
  Future<Either<Failure, Unit>> sync({
    required void Function(SyncProgress progress) onProgress,
  }) async {
    final run = runs++;
    for (final p in progress) {
      onProgress(p);
    }
    if (hold) {
      await _gate.future;
      _gate = Completer<void>();
    }
    return results[run < results.length ? run : results.length - 1];
  }
}
