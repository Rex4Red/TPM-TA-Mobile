class MangaDetail {
  final String title;
  final String cover;
  final String synopsis;
  final String author;
  final String status;
  final List<Chapter> chapters;

  MangaDetail({
    required this.title,
    required this.cover,
    required this.synopsis,
    required this.author,
    required this.status,
    required this.chapters,
  });

  factory MangaDetail.fromJson(Map<String, dynamic> json) {
    // Parsing list chapter dari JSON ke List<Chapter>
    var list = json['chapters'] as List? ?? [];
    List<Chapter> chapterList = list.map((i) => Chapter.fromJson(i)).toList();

    return MangaDetail(
      title: json['title'] ?? 'Tanpa Judul',
      cover: json['cover'] ?? '',
      synopsis: json['synopsis'] ?? 'Tidak ada sinopsis',
      author: json['author'] ?? 'Unknown',
      status: json['status'] ?? 'Unknown',
      chapters: chapterList,
    );
  }
}

class Chapter {
  final String id;
  final String title;
  final String date;

  Chapter({required this.id, required this.title, required this.date});

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      date: json['date'] ?? '',
    );
  }
}