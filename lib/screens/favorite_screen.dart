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
      backgroundColor: FavoriteScreenColors.background,
      appBar: AppBar(
        title: const Text("Koleksi Favorit ❤️", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: FavoriteScreenColors.appBarBg,
        foregroundColor: FavoriteScreenColors.appBarText,
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
                  Icon(Icons.favorite_border, size: 80, color: FavoriteScreenColors.emptyIcon),
                  const SizedBox(height: 10),
                  Text("Belum ada favorit.", style: TextStyle(color: FavoriteScreenColors.emptyText)),
                  const SizedBox(height: 5),
                  Text("Coba love beberapa komik dulu!", style: TextStyle(color: FavoriteScreenColors.emptyText, fontSize: 12)),
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
                    color: FavoriteScreenColors.cardBg,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: FavoriteScreenColors.cardShadow, blurRadius: 3)],
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
                            placeholder: (c, u) => Container(color: FavoriteScreenColors.placeholder),
                            errorWidget: (c, u, e) => Icon(Icons.broken_image, color: FavoriteScreenColors.emptyText),
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
                              style: TextStyle(color: FavoriteScreenColors.mangaTitle, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            // Badge Tipe Source (Opsional: Biar tau ini dari mana)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: item['source'] == 'shinigami' ? FavoriteScreenColors.shinigamiBadge.withOpacity(0.2) : FavoriteScreenColors.komikindoBadge.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4)
                              ),
                              child: Text(
                                item['source'] == 'shinigami' ? "Shinigami" : "KomikIndo",
                                style: TextStyle(
                                  color: item['source'] == 'shinigami' ? FavoriteScreenColors.shinigamiBadge : FavoriteScreenColors.komikindoBadge,
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


class FavoriteScreenColors {
  static const background      = Colors.black;        // Background halaman favorit
  static const appBarBg        = Colors.black87;      // Background AppBar
  static const appBarText      = Colors.white;        // Teks & ikon AppBar
  static const mangaTitle      = Colors.white;        // Judul manga di card
  static final cardBg          = Colors.grey[900];    // Background card manga
  static final cardShadow      = Colors.black.withOpacity(0.3); // Shadow card
  static final placeholder     = Colors.grey[800];    // Placeholder loading gambar
  static final emptyIcon       = Colors.grey[800];    // Ikon hati kosong (empty state)
  static const emptyText       = Colors.grey;         // Teks "Belum ada favorit"
  static const shinigamiBadge  = Colors.redAccent;    // Badge & teks Shinigami
  static const komikindoBadge  = Colors.blueAccent;   // Badge & teks KomikIndo
}
