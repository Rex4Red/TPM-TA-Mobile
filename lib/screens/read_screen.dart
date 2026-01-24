import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../services/history_service.dart'; // Import Service History

class ReadScreen extends StatefulWidget {
  final String source;
  final String mangaId;      // Tambahan: ID Manga
  final String mangaTitle;   // Tambahan: Judul Manga
  final String mangaCover;   // Tambahan: Cover Manga
  final String chapterId;
  final String chapterTitle;

  const ReadScreen({
    super.key,
    required this.source,
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.chapterId,
    required this.chapterTitle,
  });

  @override
  State<ReadScreen> createState() => _ReadScreenState();
}

class _ReadScreenState extends State<ReadScreen> {
  late Future<List<String>> _imagesFuture;
  final HistoryService _historyService = HistoryService();

  @override
  void initState() {
    super.initState();
    _imagesFuture = ApiService().fetchChapterImages(
      source: widget.source,
      chapterId: widget.chapterId,
    );
    
    // --- AUTO SAVE KE HISTORY ---
    _saveToHistory();
  }

  void _saveToHistory() {
    _historyService.addToHistory(
      mangaId: widget.mangaId,
      mangaTitle: widget.mangaTitle,
      mangaCover: widget.mangaCover,
      chapterId: widget.chapterId,
      chapterTitle: widget.chapterTitle,
      source: widget.source,
    );
    _historyService.markChapterAsRead(widget.mangaId, widget.chapterId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.mangaTitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            Text(widget.chapterTitle, style: const TextStyle(fontSize: 16)),
          ],
        ),
        backgroundColor: Colors.black.withOpacity(0.8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<String>>(
        future: _imagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Tidak ada gambar.", style: TextStyle(color: Colors.white)));
          }

          final images = snapshot.data!;

          return InteractiveViewer(
            minScale: 1.0,
            maxScale: 3.0,
            child: ListView.builder(
              cacheExtent: 5000, 
              itemCount: images.length,
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.fitWidth,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: Colors.grey[900],
                    child: const Center(child: CircularProgressIndicator(color: Colors.grey)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 100,
                    color: Colors.grey[900],
                    child: const Icon(Icons.broken_image, color: Colors.red),
                  ),
                  httpHeaders: const {
                    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                    "Referer": "https://google.com"
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}