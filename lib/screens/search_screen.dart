import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../models/manga_model.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Manga> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  void _doSearch() async {
    if (_searchController.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _searchResults = [];
    });

    try {
      // 🔥 DUAL SEARCH: Cari di Shinigami DAN KomikIndo secara bersamaan 🔥
      final results = await Future.wait([
        // 1. Request ke Shinigami (Pastikan parameter 'query' diisi)
        ApiService().fetchMangaList(
          source: 'shinigami', 
          query: _searchController.text, 
        ),
        // 2. Request ke KomikIndo
        ApiService().fetchMangaList(
          source: 'komikindo', 
          query: _searchController.text, 
        ),
      ]);

      // Gabungkan hasil dari kedua sumber
      final combinedList = [...results[0], ...results[1]];

      if (mounted) {
        setState(() {
          _searchResults = combinedList;
        });
      }
    } catch (e) {
      print("Error Search: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Header Http agar gambar bisa loading (Bypass 403)
  Map<String, String> _getHeaders(String source) {
    const userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";
    if (source == 'shinigami') {
      return {"User-Agent": userAgent, "Referer": "https://shinigami.id/"};
    }
    return {"User-Agent": userAgent, "Referer": "https://komikindo.tv/"};
  }

  // Validasi URL Gambar
  String _validateUrl(String? url) {
    if (url == null || url.isEmpty || url == 'null') {
      return "https://placehold.co/200x300/333/fff.png?text=No+Image";
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text("Cari Komik", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // --- KOLOM INPUT PENCARIAN ---
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[900],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Naruto, One Piece...",
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.black,
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _doSearch(), 
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _doSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent, // Merah biar semangat
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.search, color: Colors.white),
                ),
              ],
            ),
          ),

          // --- HASIL PENCARIAN ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _hasSearched ? "Tidak ditemukan" : "Cari di Shinigami & KomikIndo sekaligus!", 
                          style: TextStyle(color: Colors.grey[600])
                        )
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, 
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final manga = _searchResults[index];
                          final imageUrl = _validateUrl(manga.image);
                          final isShinigami = manga.type == 'shinigami';

                          return GestureDetector(
                            onTap: () {
                              // Navigasi ke Detail
                              Navigator.push(context, MaterialPageRoute(builder: (context) => DetailScreen(
                                source: manga.type, 
                                mangaId: manga.id, 
                                title: manga.title, 
                                cover: imageUrl,
                              )));
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      // Gambar Cover
                                      Positioned.fill(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: CachedNetworkImage(
                                            imageUrl: imageUrl,
                                            httpHeaders: _getHeaders(manga.type), 
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(color: Colors.grey[800]),
                                            errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                      // Badge Source (Penting buat bedain sumber)
                                      Positioned(
                                        top: 6, right: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: (isShinigami ? Colors.redAccent : Colors.blueAccent).withOpacity(0.9), 
                                            borderRadius: BorderRadius.circular(6)
                                          ),
                                          child: Text(
                                            isShinigami ? 'Shinigami' : 'KomikIndo', 
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                                          ),
                                        ),
                                      ),
                                      // Badge Score/Chapter (Opsional)
                                      Positioned(
                                        bottom: 0, left: 0, right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                                            ),
                                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8))
                                          ),
                                          child: Text(
                                            manga.chapter,
                                            style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w600),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  manga.title, 
                                  maxLines: 2, 
                                  overflow: TextOverflow.ellipsis, 
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}