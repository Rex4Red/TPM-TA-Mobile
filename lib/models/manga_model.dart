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

  // 🔥 UPDATE: Tambahkan parameter 'source' di sini
  factory Manga.fromJson(Map<String, dynamic> json, String source) {
    return Manga(
      id: json['id']?.toString() ?? json['endpoint'] ?? '',
      title: json['title']?.toString() ?? 'Tanpa Judul',
      // Cek semua kemungkinan key gambar
      image: json['image'] ?? json['thumb'] ?? json['thumbnail'] ?? json['cover'] ?? '',
      chapter: json['chapter']?.toString() ?? 'Ch. ?',
      score: json['score']?.toString() ?? 'N/A',
      // 🔥 PENTING: Pakai source dari parameter, jangan dari json yang mungkin null
      type: source, 
    );
  }
}