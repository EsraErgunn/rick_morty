import '../../../../core/network/endpoints.dart';

/// API JSON'u için katı alan erişimi. Bir alan eksikse ya da tipi yanlışsa
/// alan adıyla [FormatException] fırlatır; eşleyiciler bunu bir
/// `ParseFailure`'a çevirir.
extension JsonReader on Map<String, dynamic> {
  T field<T>(String key) {
    final value = this[key];
    if (value is T) return value;
    throw FormatException(
      'field "$key": expected $T, got ${value.runtimeType}',
    );
  }

  Map<String, dynamic> object(String key) => field<Map<String, dynamic>>(key);

  /// Id'lerine eşlenmiş kaynak URL'leri listesi.
  List<int> idsFromUrls(String key) => [
    for (final url in field<List<dynamic>>(key))
      if (url is String)
        Endpoints.idFromUrl(url) ??
            (throw FormatException('field "$key": no id in "$url"'))
      else
        throw FormatException('field "$key": expected URL strings'),
  ];

  /// `url` alanının sonundaki id; URL boşsa null
  /// (API bilinmeyen köken veya konum için "" kullanır).
  int? optionalIdFromUrl(String key) {
    final url = field<String>(key);
    return url.isEmpty ? null : Endpoints.idFromUrl(url);
  }
}
