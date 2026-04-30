import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../services/api_service.dart';
import '../models/manga_model.dart';
import '../widgets/modern_manga_card.dart';
import 'search_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text(
                "MangaMotion",
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              centerTitle: false,
              backgroundColor: const Color(0xFF121212),
              floating: true,
              pinned: true,
              snap: true,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.person, size: 18, color: Colors.white),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.blueAccent,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: "Shinigami"),
                  Tab(text: "KomikIndo"),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: const [ShinigamiHomeView(), KomikIndoHomeView()],
        ),
      ),
    );
  }
}

// 🔥 WIDGET PINTAR UNTUK LOADING & RETRY 🔥
// Ini adalah "Mesin" yang akan mencoba membangunkan server berkali-kali
class SmartLoader extends StatefulWidget {
  final String source;
  final String section;
  final String? type;
  final Widget Function(List<Manga>, {VoidCallback? onLoadMore, bool isLoadingMore, bool hasMore}) onSuccess;
  final Widget Function()? onEmpty;
  final bool enablePagination;

  const SmartLoader({
    super.key,
    required this.source,
    required this.section,
    this.type,
    required this.onSuccess,
    this.onEmpty,
    this.enablePagination = false,
  });

  @override
  State<SmartLoader> createState() => _SmartLoaderState();
}

class _SmartLoaderState extends State<SmartLoader> {
  List<Manga> _data = [];
  bool _isLoading = true;
  String _statusMsg = "Memuat data...";
  bool _isError = false;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _startAutoRetry();
  }

  // Logika Retry Pintar
  void _startAutoRetry() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isError = false;
      _currentPage = 1;
      _data = [];
      _hasMore = true;
    });

    int maxAttempts = 20;
    int attempt = 0;
    int emptyCount = 0; // Counter khusus untuk respons kosong

    while (attempt < maxAttempts) {
      if (!mounted) return;
      try {
        setState(
          () => _statusMsg = attempt == 0
              ? "Menghubungkan..."
              : "Membangunkan Server... (${attempt + 1}/$maxAttempts)",
        );

        // Request Data
        final data = await ApiService().fetchMangaList(
          source: widget.source,
          section: widget.section,
          type: widget.type,
        );

        if (data.isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _data = data;
            _isLoading = false;
            _hasMore = data.length >= 5;
          });
          return; // Sukses! Keluar dari loop
        }

        // Server merespons tapi data kosong
        emptyCount++;
        if (emptyCount >= 3) {
          // Sudah 3x dapat respons kosong → kemungkinan scraper memang down
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _isError = true;
            _statusMsg = "Data tidak tersedia saat ini.";
          });
          return;
        }

        throw Exception("Data Kosong");
      } catch (e) {
        attempt++;
        print("⚠️ [${widget.source}] Retry $attempt: $e");

        if (attempt >= maxAttempts) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _isError = true;
          });
          return; // Nyerah
        }

        // Tunggu 3 detik sebelum coba lagi
        await Future.delayed(const Duration(seconds: 3));
      }
    }
  }

  // Load More Pages
  void _loadMore() async {
    if (_isLoadingMore || !_hasMore || !widget.enablePagination) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      final nextPage = _currentPage + 1;
      final newData = await ApiService().fetchMangaList(
        source: widget.source,
        section: widget.section,
        type: widget.type,
        page: nextPage,
      );

      if (!mounted) return;
      
      if (newData.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _data.addAll(newData);
          _currentPage = nextPage;
          _isLoadingMore = false;
          _hasMore = newData.length >= 5;
        });
      }
    } catch (e) {
      print("❌ LoadMore Error: $e");
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Tampilan Loading dengan Status
    if (_isLoading) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.blueAccent),
              const SizedBox(height: 12),
              Text(
                _statusMsg,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Tampilan Error / Gagal (Tombol Manual)
    if (_isError || _data.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, color: Colors.white24, size: 40),
              const SizedBox(height: 8),
              const Text(
                "Server masih tertidur lelap.",
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _startAutoRetry,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  "Bangunkan Paksa!",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Tampilan Sukses
    return widget.onSuccess(
      _data,
      onLoadMore: widget.enablePagination ? _loadMore : null,
      isLoadingMore: _isLoadingMore,
      hasMore: _hasMore,
    );
  }
}

// ==========================================
// 1. SHINIGAMI VIEW (Updated)
// ==========================================
class ShinigamiHomeView extends StatefulWidget {
  const ShinigamiHomeView({super.key});

  @override
  State<ShinigamiHomeView> createState() => _ShinigamiHomeViewState();
}

class _ShinigamiHomeViewState extends State<ShinigamiHomeView> {
  String _selectedRecType = 'manhwa';
  String _selectedLatestType = 'project';

  // Kita pakai Key untuk memaksa widget reload saat refresh/ganti filter
  Key _recKey = UniqueKey();
  Key _latestKey = UniqueKey();

  void _refresh() {
    setState(() {
      _recKey = UniqueKey();
      _latestKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Colors.blueAccent,
      backgroundColor: Colors.grey[900],
      onRefresh: () async => _refresh(),
      child: CustomScrollView(
        slivers: [
          // REKOMENDASI (Carousel)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHeader("Featured Series 🔥", _selectedRecType, (val) {
                  setState(() {
                    _selectedRecType = val;
                    _recKey = UniqueKey();
                  });
                }, isRec: true),
                const SizedBox(height: 15),

                // Panggil SmartLoader
                SmartLoader(
                  key: _recKey, // Penting biar bisa direfresh
                  source: 'shinigami',
                  section: 'recommended',
                  type: _selectedRecType,
                  onSuccess: (data, {onLoadMore, isLoadingMore = false, hasMore = false}) => CarouselSlider(
                    options: CarouselOptions(
                      height: 220,
                      aspectRatio: 16 / 9,
                      viewportFraction: 0.45,
                      enlargeCenterPage: true,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 5),
                    ),
                    items: data
                        .map(
                          (manga) => ModernMangaCard(
                            manga: manga,
                            isFeatured: true,
                            sourceMaster: 'shinigami',
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // LATEST UPDATE (Grid)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 30, 16, 10),
              child: _buildHeader("Latest Updates 🚀", _selectedLatestType, (
                val,
              ) {
                setState(() {
                  _selectedLatestType = val;
                  _latestKey = UniqueKey();
                });
              }, isRec: false),
            ),
          ),

          // Panggil SmartLoader tapi dibungkus SliverToBoxAdapter karena Grid ada di dalamnya
          SliverToBoxAdapter(
            child: SmartLoader(
              key: _latestKey,
              source: 'shinigami',
              section: 'latest',
              type: _selectedLatestType,
              enablePagination: true,
              onSuccess: (data, {onLoadMore, isLoadingMore = false, hasMore = false}) => Column(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.65,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: data.length,
                    itemBuilder: (context, index) => ModernMangaCard(
                      manga: data[index],
                      sourceMaster: 'shinigami',
                    ),
                  ),
                  if (isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: Colors.blueAccent),
                    ),
                  if (!isLoadingMore && hasMore && onLoadMore != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: ElevatedButton.icon(
                        onPressed: onLoadMore,
                        icon: const Icon(Icons.expand_more),
                        label: const Text('Muat Lebih Banyak'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 150)),
        ],
      ),
    );
  }

  Widget _buildHeader(
    String title,
    String selectedVal,
    Function(String) onSelect, {
    required bool isRec,
  }) {
    final filters = isRec
        ? {'Manhwa': 'manhwa', 'Manhua': 'manhua', 'Manga': 'manga'}
        : {'Project': 'project', 'Mirror': 'mirror'};
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.blueAccent),
            color: Colors.grey[900],
            onSelected: (val) => onSelect(val),
            itemBuilder: (context) => filters.entries
                .map(
                  (e) => PopupMenuItem(
                    value: e.value,
                    child: Text(
                      e.key,
                      style: TextStyle(
                        color: selectedVal == e.value
                            ? Colors.blueAccent
                            : Colors.white,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. KOMIKINDO VIEW (Updated)
// ==========================================
class KomikIndoHomeView extends StatefulWidget {
  const KomikIndoHomeView({super.key});

  @override
  State<KomikIndoHomeView> createState() => _KomikIndoHomeViewState();
}

class _KomikIndoHomeViewState extends State<KomikIndoHomeView> {
  Key _key = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Colors.blueAccent,
      backgroundColor: Colors.grey[900],
      onRefresh: () async => setState(() => _key = UniqueKey()),
      child: CustomScrollView(
        slivers: [
          // POPULAR
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 15),
                  child: Text(
                    "Most Popular ⭐",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SmartLoader(
                  key: Key("pop_$_key"), // Key unik biar refresh jalan
                  source: 'komikindo',
                  section: 'popular',
                  onSuccess: (data, {onLoadMore, isLoadingMore = false, hasMore = false}) => CarouselSlider(
                    options: CarouselOptions(
                      height: 220,
                      aspectRatio: 16 / 9,
                      viewportFraction: 0.45,
                      enlargeCenterPage: true,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 6),
                    ),
                    items: data
                        .map(
                          (manga) => ModernMangaCard(
                            manga: manga,
                            isFeatured: true,
                            sourceMaster: 'komikindo',
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // LATEST
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 30, 16, 10),
              child: Text(
                "Latest Updates ⚡",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SmartLoader(
              key: Key("latest_$_key"),
              source: 'komikindo',
              section: 'latest',
              enablePagination: true,
              onSuccess: (data, {onLoadMore, isLoadingMore = false, hasMore = false}) => Column(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.65,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: data.length,
                    itemBuilder: (context, index) => ModernMangaCard(
                      manga: data[index],
                      sourceMaster: 'komikindo',
                    ),
                  ),
                  if (isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: Colors.blueAccent),
                    ),
                  if (!isLoadingMore && hasMore && onLoadMore != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: ElevatedButton.icon(
                        onPressed: onLoadMore,
                        icon: const Icon(Icons.expand_more),
                        label: const Text('Muat Lebih Banyak'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 150)),
        ],
      ),
    );
  }
}
