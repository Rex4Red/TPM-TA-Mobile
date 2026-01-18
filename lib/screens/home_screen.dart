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
            ShinigamiHomeView(), 
            KomikIndoHomeView(), 
          ],
        ),
        backgroundColor: Colors.black,
      ),
    );
  }
}

// ==========================================
// 1. SHINIGAMI VIEW 
// ==========================================
class ShinigamiHomeView extends StatefulWidget {
  const ShinigamiHomeView({super.key});

  @override
  State<ShinigamiHomeView> createState() => _ShinigamiHomeViewState();
}

class _ShinigamiHomeViewState extends State<ShinigamiHomeView> {
  String _selectedRecType = 'manhwa'; 
  String _selectedLatestType = 'project'; 

  late Future<List<Manga>> _recommendedManga;
  late Future<List<Manga>> _latestManga;

  @override
  void initState() {
    super.initState();
    _fetchRecommended();
    _fetchLatest();
  }

  void _fetchRecommended() {
    setState(() {
      _recommendedManga = ApiService().fetchMangaList(
        source: 'shinigami', 
        section: 'recommended', 
        type: _selectedRecType 
      );
    });
  }

  void _fetchLatest() {
    setState(() {
      _latestManga = ApiService().fetchMangaList(
        source: 'shinigami', 
        section: 'latest', 
        type: _selectedLatestType 
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async { _fetchRecommended(); _fetchLatest(); },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // REKOMENDASI TITLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text("Rekomendasi 🔥", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            
            // FILTER CHIPS
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip("Manhwa", 'manhwa', true),
                  _buildFilterChip("Manhua", 'manhua', true),
                  _buildFilterChip("Manga", 'manga', true),
                ],
              ),
            ),

            // LIST HORIZONTAL REKOMENDASI
            SizedBox(
              height: 240,
              child: FutureBuilder<List<Manga>>(
                future: _recommendedManga,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Tidak ada data", style: TextStyle(color: Colors.grey)));

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 10),
                        // Shinigami Rekomendasi tetap tampilkan chapter
                        child: MangaCard(manga: snapshot.data![index]),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // UPDATE TERBARU TITLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text("Update Terbaru 🕒", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            // FILTER CHIPS LATEST
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip("Project", 'project', false),
                  const SizedBox(width: 10),
                  _buildFilterChip("Mirror", 'mirror', false),
                ],
              ),
            ),

            // GRID VERTICAL LATEST
            FutureBuilder<List<Manga>>(
              future: _latestManga,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(50), child: Center(child: CircularProgressIndicator()));
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Tidak ada update terbaru", style: TextStyle(color: Colors.grey)));

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return MangaCard(manga: snapshot.data![index]);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isRec) {
    final isSelected = isRec ? _selectedRecType == value : _selectedLatestType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) {
            setState(() {
              if (isRec) {
                _selectedRecType = value;
                _fetchRecommended();
              } else {
                _selectedLatestType = value;
                _fetchLatest();
              }
            });
          }
        },
        selectedColor: Colors.blueAccent,
        backgroundColor: Colors.grey[800],
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey[400]),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

// ==========================================
// 2. KOMIKINDO VIEW 
// ==========================================
class KomikIndoHomeView extends StatefulWidget {
  const KomikIndoHomeView({super.key});

  @override
  State<KomikIndoHomeView> createState() => _KomikIndoHomeViewState();
}

class _KomikIndoHomeViewState extends State<KomikIndoHomeView> {
  late Future<List<Manga>> _popularList;
  late Future<List<Manga>> _latestList;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _popularList = ApiService().fetchMangaList(source: 'komikindo', section: 'popular');
      _latestList = ApiService().fetchMangaList(source: 'komikindo', section: 'latest');
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _fetchData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- POPULAR (Horizontal) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: const [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Text("Komik Terpopuler 🔥", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            SizedBox(
              height: 240, 
              child: FutureBuilder<List<Manga>>(
                future: _popularList,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Tidak ada data populer", style: TextStyle(color: Colors.grey)));

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 140, 
                        margin: const EdgeInsets.only(right: 10),
                        // 🔥 HILANGKAN CHAPTER DI SINI (showChapter: false)
                        child: MangaCard(manga: snapshot.data![index], showChapter: false),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // --- UPDATE TERBARU (Vertical Grid) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: const [
                  Icon(Icons.new_releases, color: Colors.blueAccent, size: 20),
                  SizedBox(width: 8),
                  Text("Update Terbaru 🚀", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            FutureBuilder<List<Manga>>(
              future: _latestList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(50), child: Center(child: CircularProgressIndicator()));
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Tidak ada update terbaru", style: TextStyle(color: Colors.grey)));

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), 
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    // Update terbaru tetap tampilkan chapter (default true)
                    return MangaCard(manga: snapshot.data![index]);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// WIDGET KARTU (UPDATED with showChapter)
// ==========================================
class MangaCard extends StatelessWidget {
  final Manga manga;
  final bool showChapter; // Parameter baru untuk kontrol chapter

  const MangaCard({
    super.key, 
    required this.manga,
    this.showChapter = true, // Default true (tampilkan chapter)
  });

  String _makeUrlSafe(String url, String source) {
    if (url.isEmpty || url == 'null') return "https://placehold.co/200x300/333/fff.png?text=No+Image";
    if (source == 'shinigami') return "https://wsrv.nl/?url=${Uri.encodeComponent(url)}&w=300&output=webp";
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _makeUrlSafe(manga.image, manga.type);

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => DetailScreen(
          source: manga.type, mangaId: manga.id, title: manga.title, cover: imageUrl
        )));
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
                  Text(manga.title, maxLines: 2, overflow: TextOverflow.ellipsis, 
                       style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // LOGIKA SHOW/HIDE CHAPTER
                      if (showChapter) 
                        Flexible(
                          child: Text(
                            manga.chapter, 
                            style: const TextStyle(color: Colors.blueAccent, fontSize: 10), 
                            overflow: TextOverflow.ellipsis
                          )
                        ),
                      
                      if (manga.score != 'N/A') 
                        Text("⭐ ${manga.score}", style: const TextStyle(color: Colors.amber, fontSize: 10)),
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