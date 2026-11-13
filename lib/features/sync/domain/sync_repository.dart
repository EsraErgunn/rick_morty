import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';

/// Karakterler, bölümler ve konumlar genelinde şimdiye kadar indirilen öğeler.
final class SyncProgress extends Equatable {
  const SyncProgress({required this.downloaded, required this.total});

  final int downloaded;

  /// Üç kaynağın `info.count` toplamı (bilinene kadar 0).
  final int total;

  /// 0.0 ile 1.0 arası.
  double get fraction => total == 0 ? 0 : (downloaded / total).clamp(0, 1);

  /// Tam yüzde, 0 ile 100 arası.
  int get percent => (fraction * 100).floor();

  @override
  List<Object?> get props => [downloaded, total];
}

/// API'nin ilk açılışta yerel depolamaya indirilmesi (SPEC §2.1).
abstract interface class SyncRepository {
  /// Tam bir senkron bitince true; sonraki açılışlar ağı atlar.
  bool get isSynced;

  /// Eksik olanı sayfa sayfa indirir, son tamamlanan sayfadan sonra
  /// devam eder. Kaydedilen her sayfadan sonra ilerlemeyi bildirir. Bir hata
  /// o ana kadar kaydedilen her şeyi korur.
  Future<Either<Failure, Unit>> sync({
    required void Function(SyncProgress progress) onProgress,
  });
}
