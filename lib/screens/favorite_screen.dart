import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/bookmark_service.dart';
import 'detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final BookmarkService _bookmarkService = BookmarkService();
  late Future<List<Map<String, dynamic>>> _bookmarks;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _bookmarks = _bookmarkService.getBookmarks();
    });
  }

  // 🔥 FUNGSI SAKTI: Agar gambar Shinigami tidak broken 🔥

  String _makeUrlSafe(String url, String source) {
    if (url.isEmpty || url == 'null') return "https://placehold.co/200x300/333/fff.png?text=No+Image";
    
    // CEK: Jika URL sudah mengandung 'wsrv.nl', berarti sudah aman. Jangan di-proxy lagi!
    if (url.contains("wsrv.nl")) {
      return url;
    }

    // Proxy WSRV hanya untuk Shinigami yang belum di-proxy
    if (source == 'shinigami') {
      return "https://wsrv.nl/?url=${Uri.encodeComponent(url)}&w=300&output=webp";
    }
    
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Koleksi Favorit ❤️", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _bookmarks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey[800]),
                  const SizedBox(height: 10),
                  const Text("Belum ada favorit.", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 5),
                  const Text("Coba love beberapa komik dulu!", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          final data = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              
              // Terapkan Fix Image URL
              final imageUrl = _makeUrlSafe(item['cover'], item['source']);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(
                        source: item['source'],
                        mangaId: item['manga_id'],
                        title: item['title'],
                        cover: imageUrl, // Kirim URL yang sudah safe
                      ),
                    ),
                  ).then((_) => _refreshData()); // Refresh saat kembali (jika di-unlove)
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 3)],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (c, u) => Container(color: Colors.grey[800]),
                            errorWidget: (c, u, e) => const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            // Badge Tipe Source (Opsional: Biar tau ini dari mana)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: item['source'] == 'shinigami' ? Colors.redAccent.withOpacity(0.2) : Colors.blueAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4)
                              ),
                              child: Text(
                                item['source'] == 'shinigami' ? "Shinigami" : "KomikIndo",
                                style: TextStyle(
                                  color: item['source'] == 'shinigami' ? Colors.redAccent : Colors.blueAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}