import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../models/manga_model.dart';
import 'detail_screen.dart'; // Navigasi ke Detail
import 'profile_screen.dart'; // Navigasi ke Profil/Login

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // DefaultTabController membungkus Scaffold agar TabBar berfungsi
    return DefaultTabController(
      length: 2, // Jumlah Tab (Shinigami & KomikIndo)
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Rex4Red Manga", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          
          // --- TOMBOL PROFIL DI POJOK KANAN ---
          actions: [
            IconButton(
              icon: const Icon(Icons.account_circle),
              tooltip: 'Profil Saya',
              onPressed: () {
                // Buka halaman ProfileScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
          ],
          // -----------------------------------

          bottom: const TabBar(
            indicatorColor: Colors.blue,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Shinigami"),
              Tab(text: "KomikIndo"),
            ],
          ),
        ),
        // Body berisi 2 halaman sesuai Tab yang dipilih
        body: const TabBarView(
          children: [
            MangaGrid(source: 'shinigami'),
            MangaGrid(source: 'komikindo'),
          ],
        ),
        backgroundColor: Colors.black, // Background gelap
      ),
    );
  }
}

// --- WIDGET GRID MANGA (DIPISAH SUPAYA RAPI) ---
class MangaGrid extends StatefulWidget {
  final String source;
  const MangaGrid({super.key, required this.source});

  @override
  State<MangaGrid> createState() => _MangaGridState();
}

class _MangaGridState extends State<MangaGrid> {
  late Future<List<Manga>> _mangaList;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Fungsi memanggil API
  void _fetchData() {
    setState(() {
      _mangaList = ApiService().fetchMangaList(source: widget.source);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Manga>>(
      future: _mangaList,
      builder: (context, snapshot) {
        // 1. Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Error State
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 50),
                const SizedBox(height: 10),
                Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: _fetchData, child: const Text("Coba Lagi"))
              ],
            ),
          );
        }

        // 3. Empty State
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Tidak ada data.", style: TextStyle(color: Colors.white)));
        }

        // 4. Success State (Tampilkan Grid)
        final data = snapshot.data!;
        
        // RefreshIndicator agar bisa tarik layar ke bawah untuk reload
        return RefreshIndicator(
          onRefresh: () async => _fetchData(),
          child: GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 Kolom ke samping
              childAspectRatio: 0.7, // Perbandingan Tinggi vs Lebar kartu
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final manga = data[index];
              return _buildMangaCard(manga);
            },
          ),
        );
      },
    );
  }

  // Widget Kartu Komik Individual
  Widget _buildMangaCard(Manga manga) {
    return GestureDetector(
      onTap: () {
        // Navigasi ke Halaman Detail saat kartu diklik
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailScreen(
              source: manga.type,
              mangaId: manga.id,
              title: manga.title,
              cover: manga.image,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gambar Cover
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: CachedNetworkImage(
                  imageUrl: manga.image,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[800]),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                  // Header penting untuk melewati proteksi gambar
                  httpHeaders: const {
                     "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                     "Referer": "https://google.com"
                  },
                ),
              ),
            ),
            // Info Teks di Bawah Gambar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manga.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        manga.chapter,
                        style: const TextStyle(color: Colors.blueAccent, fontSize: 10),
                      ),
                      if (manga.score != '0' && manga.score != 'N/A')
                        Text(
                          "⭐ ${manga.score}",
                          style: const TextStyle(color: Colors.amber, fontSize: 10),
                        ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}