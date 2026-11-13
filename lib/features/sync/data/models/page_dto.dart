import 'json_reader.dart';

/// Bir liste sayfası: `info` (toplamlar) + `results` [CLAUDE.md tuzakları: sayıları
/// asla sabit yazma, `info.count` / `info.pages` oku].
class PageDto<T> {
  const PageDto({
    required this.count,
    required this.pages,
    required this.hasNext,
    required this.results,
  });

  /// Sayfa ya da herhangi bir öğe bozuksa [FormatException] fırlatır.
  factory PageDto.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) item,
  ) {
    final info = json.object('info');
    final results = json.field<List<dynamic>>('results');
    return PageDto(
      count: info.field<int>('count'),
      pages: info.field<int>('pages'),
      hasNext: info['next'] is String,
      results: [
        for (final r in results)
          if (r is Map<String, dynamic>)
            item(r)
          else
            throw const FormatException('results: expected objects'),
      ],
    );
  }

  /// Bu kaynağın toplam öğe sayısı.
  final int count;

  /// Bu kaynağın toplam sayfa sayısı.
  final int pages;
  final bool hasNext;
  final List<T> results;
}
