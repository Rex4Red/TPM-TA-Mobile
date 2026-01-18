import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../models/manga_model.dart';
import 'detail_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Rex4Red Manga", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen())),
            ),
            IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.blue,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: [Tab(text: "Shinigami"), Tab(text: "KomikIndo")],
          ),
        ),
        body: const TabBarView(
          children: [
            MangaGrid(source: 'shinigami'),
            MangaGrid(source: 'komikindo'),
          ],
        ),
        backgroundColor: Colors.black,
      ),
    );
  }
}

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

  void _fetchData() {
    setState(() {
      _mangaList = ApiService().fetchMangaList(source: widget.source);
    });
  }

  // 🔥 FUNGSI PEMBUKA BLOKIR (SANGAT PENTING) 🔥
  String _processUrl(String url, String source) {
    // 1. Jika URL kosong dari backend, pakai gambar placeholder
    if (url.isEmpty || url == 'null' || url == '') {
      return "https://placehold.co/200x300/333/fff.png?text=No+Image";
    }

    // 2. Jika Shinigami, kita BUNGKUS pakai wsrv.nl (Proxy Gambar Global)
    // Ini akan mengubah request seolah-olah bukan dari HP kamu
    if (source == 'shinigami') {
      return "https://wsrv.nl/?url=${Uri.encodeComponent(url)}&w=400&output=webp";
    }

    // 3. KomikIndo biasanya aman langsung
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Manga>>(
      future: _mangaList,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Tidak ada data.", style: TextStyle(color: Colors.white)));
        }

        return RefreshIndicator(
          onRefresh: () async => _fetchData(),
          child: GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              childAspectRatio: 0.7, 
              crossAxisSpacing: 10, mainAxisSpacing: 10
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (ctx, i) => _buildCard(snapshot.data![i]),
          ),
        );
      },
    );
  }

  Widget _buildCard(Manga manga) {
    // Proses URL agar aman
    final imageUrl = _processUrl(manga.image, manga.type);

    // 👇 DEBUG: Cek log ini di terminal kalau gambar masih tidak muncul
    if (manga.type == 'shinigami') {
      print("🖼️ SHINIGAMI IMAGE: ${manga.title}");
      print("   - Asli: ${manga.image}");
      print("   - Proxy: $imageUrl");
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => DetailScreen(
          source: manga.type, mangaId: manga.id, title: manga.title, cover: manga.image
        )));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)],
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
                  errorWidget: (c, u, e) {
                    print("❌ GAGAL LOAD: $imageUrl -> $e"); // Log jika error
                    return const Icon(Icons.broken_image, color: Colors.grey);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(manga.title, maxLines: 2, overflow: TextOverflow.ellipsis, 
                       style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(manga.chapter, style: const TextStyle(color: Colors.blueAccent, fontSize: 10), overflow: TextOverflow.ellipsis)),
                      if (manga.score != 'N/A') Text("⭐ ${manga.score}", style: const TextStyle(color: Colors.amber, fontSize: 10)),
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