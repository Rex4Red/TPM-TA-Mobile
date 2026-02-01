import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/manga_model.dart';
import '../screens/detail_screen.dart';

class ModernMangaCard extends StatelessWidget {
  final Manga manga;
  final bool isFeatured;
  final String sourceMaster; 

  const ModernMangaCard({
    super.key,
    required this.manga,
    this.isFeatured = false,
    required this.sourceMaster, 
  });

  // 1. Headers untuk KomikIndo (Wajib)
  Map<String, String> _getHeaders(String source) {
    if (source == 'shinigami') {
      // Shinigami tidak butuh headers khusus jika lewat proxy, tapi buat jaga-jaga
      return {
        "User-Agent": "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36",
        "Referer": "https://shinigami.id/"
      };
    }
    // KomikIndo butuh Headers User-Agent PC
    return {
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
      "Referer": "https://komikindo.tv/"
    };
  }

  // 2. Helper URL (🔥 PERBAIKAN UTAMA: PROXY GAMBAR SHINIGAMI 🔥)
  String _makeUrlSafe(String url, String source) {
    if (url.isEmpty || url == 'null' || url.contains('no-image')) {
       return "https://placehold.co/300x400/1a1a1a/fff.png?text=No+Image";
    }

    // Jika Shinigami, KITA WAJIB PAKAI PROXY GAMBAR (wsrv.nl)
    // wsrv.nl adalah image proxy gratis yang cepat dan bisa bypass hotlink protection
    if (source == 'shinigami') {
      // Cek apakah sudah pakai proxy atau belum
      if (!url.contains('wsrv.nl')) {
         return "https://wsrv.nl/?url=${Uri.encodeComponent(url)}&w=400&output=webp&q=80";
      }
    }
    
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _makeUrlSafe(manga.image, sourceMaster);

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => DetailScreen(
          source: sourceMaster, 
          mangaId: manga.id,
          title: manga.title,
          cover: imageUrl
        )));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 6, offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                httpHeaders: _getHeaders(sourceMaster),
                fit: BoxFit.cover,
                // Placeholder Gelap
                placeholder: (c, u) => Container(color: Colors.grey[900]),
                // Kalau Proxy gagal, coba gambar asli (Fallback)
                errorWidget: (c, u, e) {
                   // Coba load gambar asli tanpa proxy jika proxy gagal
                   if (sourceMaster == 'shinigami' && imageUrl.contains('wsrv.nl')) {
                      return Image.network(manga.image, fit: BoxFit.cover, errorBuilder: (_,__,___) => _buildErrorWidget());
                   }
                   return _buildErrorWidget();
                },
              ),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.9)],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
              // Teks Judul
              Positioned(
                bottom: 10, left: 10, right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manga.title,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isFeatured ? 15 : 11,
                        fontWeight: FontWeight.bold,
                        shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                       manga.chapter,
                       style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                       overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Badge Type
              if (manga.type.isNotEmpty && !isFeatured)
                Positioned(
                  top: 6, right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(4)),
                    child: Text(manga.type.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[900],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.white24),
          SizedBox(height: 4),
          Text("Img Error", style: TextStyle(color: Colors.white24, fontSize: 10))
        ],
      ),
    );
  }
}