class Manga {
  final String id;
  final String title;
  final String image;
  final String chapter;
  final String score;
  final String type;

  Manga({
    required this.id,
    required this.title,
    required this.image,
    required this.chapter,
    required this.score,
    required this.type,
  });

  factory Manga.fromJson(Map<String, dynamic> json) {
    return Manga(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Tanpa Judul',
      // Ambil gambar dari berbagai kemungkinan key agar tidak null
      image: json['image'] ?? json['thumb'] ?? json['thumbnail'] ?? json['cover'] ?? '',
      chapter: json['chapter']?.toString() ?? 'Ch. ?',
      score: json['score']?.toString() ?? 'N/A',
      type: json['type']?.toString() ?? 'unknown',
    );
  }
}