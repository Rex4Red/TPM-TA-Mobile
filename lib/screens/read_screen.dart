import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';

class ReadScreen extends StatefulWidget {
  final String source;
  final String chapterId;
  final String chapterTitle;

  const ReadScreen({
    super.key,
    required this.source,
    required this.chapterId,
    required this.chapterTitle,
  });

  @override
  State<ReadScreen> createState() => _ReadScreenState();
}

class _ReadScreenState extends State<ReadScreen> {
  late Future<List<String>> _imagesFuture;

  @override
  void initState() {
    super.initState();
    _imagesFuture = ApiService().fetchChapterImages(
      source: widget.source,
      chapterId: widget.chapterId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Background hitam biar nyaman
      appBar: AppBar(
        title: Text(widget.chapterTitle, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.black.withOpacity(0.8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<String>>(
        future: _imagesFuture,
        builder: (context, snapshot) {
          // 1. Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. Error
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
          }
          // 3. Data Kosong
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Tidak ada gambar.", style: TextStyle(color: Colors.white)));
          }

          final images = snapshot.data!;

          // 4. Tampilan List Gambar (Webtoon Style)
          // InteractiveViewer agar bisa di-zoom cubit (pinch to zoom)
          return InteractiveViewer(
            minScale: 1.0,
            maxScale: 3.0,
            child: ListView.builder(
              // CacheExtent agar gambar di bawah pre-load duluan biar smooth
              cacheExtent: 5000, 
              itemCount: images.length,
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.fitWidth, // Lebar menyesuaikan layar HP
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
                  // Header sakti penembus blokir
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