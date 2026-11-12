/// The public Rick and Morty API (read-only, no key, HTTPS only).
abstract final class Endpoints {
  static const String baseUrl = 'https://rickandmortyapi.com/api';

  static const String characters = '/character';
  static const String episodes = '/episode';
  static const String locations = '/location';

  /// Query for page [page] (1-based) of a list endpoint.
  static Map<String, Object> page(int page) => {'page': page};

  /// Id at the end of a resource URL, e.g. `.../character/42` → 42.
  /// Returns null if the URL does not end in a number.
  static int? idFromUrl(String url) {
    final segments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
    final last = segments.lastWhere((s) => s.isNotEmpty, orElse: () => '');
    return int.tryParse(last);
  }
}
