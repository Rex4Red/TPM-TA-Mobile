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

  // Fungsi untuk mengubah JSON dari API menjadi Object Dart
  factory Manga.fromJson(Map<String, dynamic> json) {
    return Manga(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Tanpa Judul',
      image: json['image'] ?? '',
      chapter: json['chapter'] ?? '',
      score: json['score'].toString(), // Pastikan jadi string
      type: json['type'] ?? 'shinigami',
    );
  }
}