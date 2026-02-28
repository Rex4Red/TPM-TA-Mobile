class Manga {
  final String id;
  final String title;
  final String image;
  final String chapter;
  final String score;
  final String type; // 'shinigami' atau 'komikindo'

  Manga({
    required this.id,
    required this.title,
    required this.image,
    required this.chapter,
    required this.score,
    required this.type,
  });

  // 🔥 UPDATE: Support multiple API response formats
  factory Manga.fromJson(Map<String, dynamic> json, String source) {
    // Extract ID: bisa dari 'id' langsung, atau dari 'url' query param
    String mangaId = json['id']?.toString() ?? json['endpoint'] ?? '';
    if (mangaId.isEmpty && json['url'] != null) {
      final url = json['url'].toString();
      // Parse ID dari URL: ?page=manga&id=16975
      final uri = Uri.tryParse(url);
      if (uri != null && uri.queryParameters.containsKey('id')) {
        mangaId = uri.queryParameters['id']!;
      } else {
        // Fallback: ambil segment terakhir dari URL
        mangaId = url.split('/').last;
      }
    }

    // Extract latest chapter
    String chapter = json['chapter']?.toString() ?? 'Ch. ?';
    // Komikindo API baru: chapter ada di nested 'data' object
    if (json['data'] != null && json['data'] is Map) {
      chapter = json['data']['chapter']?.toString() ?? chapter;
    }

    return Manga(
      id: mangaId,
      title: json['title']?.toString() ?? 'Tanpa Judul',
      // Cek semua kemungkinan key gambar
      image: json['image'] ?? json['img'] ?? json['thumb'] ?? json['thumbnail'] ?? json['cover'] ?? '',
      chapter: chapter,
      score: json['score']?.toString() ?? 'N/A',
      // 🔥 PENTING: Pakai source dari parameter, jangan dari json yang mungkin null
      type: source, 
    );
  }
}
