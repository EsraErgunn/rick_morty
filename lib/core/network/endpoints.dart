/// Herkese açık Rick and Morty API'si (salt okunur, anahtarsız, yalnızca HTTPS).
abstract final class Endpoints {
  static const String baseUrl = 'https://rickandmortyapi.com/api';

  static const String characters = '/character';
  static const String episodes = '/episode';
  static const String locations = '/location';

  /// Bir liste uç noktasının [page] sayfası için sorgu (1'den başlar).
  static Map<String, Object> page(int page) => {'page': page};

  /// Bir kaynak URL'sinin sonundaki id, ör. `.../character/42` → 42.
  /// URL bir sayıyla bitmiyorsa null döner.
  static int? idFromUrl(String url) {
    final segments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
    final last = segments.lastWhere((s) => s.isNotEmpty, orElse: () => '');
    return int.tryParse(last);
  }
}
