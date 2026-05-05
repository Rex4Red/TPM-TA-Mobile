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

      // 🔥 SORT BY RELEVANCE: Urutkan dari yang paling relevan 🔥
      final query = _searchController.text.trim().toLowerCase();
      combinedList.sort((a, b) {
        return _relevanceScore(
          b.title,
          query,
        ).compareTo(_relevanceScore(a.title, query));
      });

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

  // 🔥 RELEVANCE SCORING: Skor kecocokan judul dengan query 🔥
  int _relevanceScore(String title, String query) {
    final titleLower = title.toLowerCase();
    if (titleLower == query) return 100; // Sama persis
    if (titleLower.startsWith(query)) return 75; // Diawali query
    // Mengandung query sebagai kata utuh
    if (RegExp(r'\b' + RegExp.escape(query) + r'\b').hasMatch(titleLower)) {
      return 50;
    }
    if (titleLower.contains(query)) return 25; // Mengandung substring
    return 0;
  }

  // Header Http agar gambar bisa loading (Bypass 403)
  Map<String, String> _getHeaders(String source) {
    const userAgent =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";
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
      backgroundColor: SearchScreenColors.background,
      appBar: AppBar(
        backgroundColor: SearchScreenColors.appBarBg,
        title: const Text("Cari Komik", style: TextStyle(color: SearchScreenColors.appBarTitle)),
        iconTheme: const IconThemeData(color: SearchScreenColors.appBarIcon),
      ),
      body: Column(
        children: [
          // --- KOLOM INPUT PENCARIAN ---
          Container(
            padding: const EdgeInsets.all(16),
            color: SearchScreenColors.searchBarBg,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: SearchScreenColors.inputText),
                    decoration: InputDecoration(
                      hintText: "Naruto, One Piece...",
                      hintStyle: TextStyle(color: SearchScreenColors.inputHint),
                      filled: true,
                      fillColor: SearchScreenColors.inputFill,
                      prefixIcon: const Icon(Icons.search, color: SearchScreenColors.inputIcon),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    onSubmitted: (_) => _doSearch(),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _doSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SearchScreenColors.searchBtnBg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: SearchScreenColors.searchBtnSpinner,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.search, color: SearchScreenColors.searchBtnIcon),
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
                      _hasSearched
                          ? "Tidak ditemukan"
                          : "Cari di Shinigami & KomikIndo sekaligus!",
                      style: TextStyle(color: SearchScreenColors.emptyText),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailScreen(
                                source: manga.type,
                                mangaId: manga.id,
                                title: manga.title,
                                cover: imageUrl,
                              ),
                            ),
                          );
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
                                        placeholder: (context, url) =>
                                            Container(color: SearchScreenColors.placeholderBg),
                                        errorWidget: (context, url, error) =>
                                            const Icon(
                                              Icons.broken_image,
                                              color: SearchScreenColors.brokenImgIcon,
                                            ),
                                      ),
                                    ),
                                  ),
                                  // Badge Source (Penting buat bedain sumber)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (isShinigami
                                                    ? SearchScreenColors.badgeShinigami
                                                    : SearchScreenColors.badgeKomikIndo)
                                                .withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isShinigami ? 'Shinigami' : 'KomikIndo',
                                        style: const TextStyle(
                                          color: SearchScreenColors.badgeText,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Badge Score/Chapter (Opsional)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            SearchScreenColors.gradientDark,
                                            Colors.transparent,
                                          ],
                                        ),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              bottom: Radius.circular(8),
                                            ),
                                      ),
                                      child: Text(
                                        manga.chapter,
                                        style: const TextStyle(
                                          color: SearchScreenColors.chapterText,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
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
                              style: const TextStyle(
                                color: SearchScreenColors.mangaTitle,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
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

// ==================== COLOR SETTINGS ====================
class SearchScreenColors {
  static const background        = Colors.black;           // Background utama
  static final appBarBg          = Colors.grey[900];       // Background AppBar
  static const appBarTitle       = Colors.white;           // Judul "Cari Komik"
  static const appBarIcon        = Colors.white;           // Ikon back AppBar

  // --- SEARCH BAR ---
  static final searchBarBg      = Colors.grey[900];       // Background area pencarian
  static const inputText         = Colors.white;           // Teks input
  static final inputHint         = Colors.grey[600];       // Hint placeholder
  static const inputFill         = Colors.black;           // Fill background input
  static const inputIcon         = Colors.grey;            // Ikon search di input

  // --- TOMBOL CARI ---
  static const searchBtnBg       = Colors.redAccent;       // Background tombol cari
  static const searchBtnSpinner  = Colors.white;           // Spinner loading tombol
  static const searchBtnIcon     = Colors.white;           // Ikon search tombol

  // --- KONTEN ---
  static final emptyText         = Colors.grey[600];       // Teks "Tidak ditemukan"
  static final placeholderBg     = Colors.grey[800];       // Background placeholder gambar
  static const brokenImgIcon     = Colors.grey;            // Ikon broken image

  // --- BADGE SOURCE ---
  static const badgeShinigami   = Colors.redAccent;       // Badge Shinigami
  static const badgeKomikIndo   = Colors.blueAccent;      // Badge KomikIndo
  static const badgeText         = Colors.white;           // Teks badge

  // --- OVERLAY & TEKS ---
  static final gradientDark      = Colors.black.withOpacity(0.8); // Gradient bawah card
  static const chapterText       = Colors.amber;           // Teks chapter
  static const mangaTitle        = Colors.white;           // Judul manga di bawah card
}
