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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Riwayat Baca"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Belum ada riwayat baca.", style: TextStyle(color: Colors.grey)),
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
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
                title: Text(
                  item['manga_title'] ?? 'Tanpa Judul',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      "Terakhir: ${item['chapter_title']}",
                      style: const TextStyle(color: Colors.blueAccent),
                    ),
                    Text(
                      "Source: ${item['source']}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
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