import 'json_reader.dart';

/// A list page: `info` (totals) + `results` [CLAUDE.md gotchas: never
/// hard-code counts, read `info.count` / `info.pages`].
class PageDto<T> {
  const PageDto({
    required this.count,
    required this.pages,
    required this.hasNext,
    required this.results,
  });

  /// Throws [FormatException] if the page or any item is malformed.
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

  /// Total items of this resource.
  final int count;

  /// Total pages of this resource.
  final int pages;
  final bool hasNext;
  final List<T> results;
}
