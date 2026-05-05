import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/history_service.dart';
import 'detail_screen.dart'; 

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _historyService.fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HistoryScreenColors.background,
      appBar: AppBar(
        title: const Text("Riwayat Baca"),
        backgroundColor: HistoryScreenColors.background,
        foregroundColor: HistoryScreenColors.appBarText,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text("Belum ada riwayat baca.", style: TextStyle(color: HistoryScreenColors.emptyText)),
            );
          }

          final historyList = snapshot.data!;

          return ListView.builder(
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final item = historyList[index];
              return ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: item['manga_cover'] ?? '',
                    width: 50,
                    height: 70,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Icon(Icons.broken_image, color: HistoryScreenColors.emptyText),
                  ),
                ),
                title: Text(
                  item['manga_title'] ?? 'Tanpa Judul',
                  style: TextStyle(color: HistoryScreenColors.mangaTitle, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      "Terakhir: ${item['chapter_title']}",
                      style: TextStyle(color: HistoryScreenColors.chapterText),
                    ),
                    Text(
                      "Source: ${item['source']}",
                      style: TextStyle(color: HistoryScreenColors.sourceText, fontSize: 12),
                    ),
                  ],
                ),
                onTap: () {
                  // 🔥 BAGIAN INI YANG DIPERBAIKI 🔥
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(
                        mangaId: item['manga_id'],
                        source: item['source'] ?? '',
                        // 👇 Kita ambil dari database history
                        title: item['manga_title'] ?? 'Tanpa Judul',
                        cover: item['manga_cover'] ?? '',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class HistoryScreenColors {
  static const background   = Colors.black;       // Background & AppBar
  static const appBarText   = Colors.white;        // Teks AppBar
  static const emptyText    = Colors.grey;         // Teks empty & ikon broken
  static const mangaTitle   = Colors.white;        // Judul manga
  static const chapterText  = Colors.blueAccent;   // Teks chapter terakhir
  static final sourceText   = Colors.grey[600];    // Teks "Source: ..."
}