import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../services/api_service.dart';
import '../services/recommendation_service.dart';
import '../models/manga_model.dart';
import '../widgets/modern_manga_card.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'chatbot_popup.dart';

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
      backgroundColor: HomeScreenColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70), // ⬅️ naikkan di sini
        child: FloatingActionButton(
          backgroundColor: HomeScreenColors.fabBg,
          onPressed: () {
            showChatbot(context);
          },
          child: const Icon(Icons.smart_toy),
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text(
                "MangaMotion",
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              centerTitle: false,
              backgroundColor: HomeScreenColors.background,
              floating: true,
              pinned: true,
              snap: true,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(Icons.search, color: HomeScreenColors.searchIcon),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  ),
                ),
                IconButton(
                  icon: CircleAvatar(
                    radius: 14,
                    backgroundColor: HomeScreenColors.avatarBg,
                    child: Icon(Icons.person, size: 18, color: HomeScreenColors.avatarIcon),
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
                indicatorColor: HomeScreenColors.tabIndicator,
                indicatorWeight: 3,
                labelColor: HomeScreenColors.tabActive,
                unselectedLabelColor: HomeScreenColors.tabInactive,
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
    void showChatbot(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChatbotPopup(),
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
              const CircularProgressIndicator(color: HomeScreenColors.spinner),
              const SizedBox(height: 12),
              Text(
                _statusMsg,
                style: TextStyle(color: HomeScreenColors.statusText, fontSize: 12),
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
              Icon(Icons.cloud_off, color: HomeScreenColors.errorIcon, size: 40),
              const SizedBox(height: 8),
                Text(
                "Server masih tertidur lelap.",
                style: TextStyle(color: HomeScreenColors.statusText),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _startAutoRetry,
                icon: Icon(Icons.refresh, color: HomeScreenColors.retryIcon),
                label: Text(
                  "Bangunkan Paksa!",
                  style: TextStyle(color: HomeScreenColors.retryText),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HomeScreenColors.buttonBg,
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

  // AI Recommendation
  final RecommendationService _recService = RecommendationService();
  List<Map<String, dynamic>> _aiRecommendations = [];
  bool _aiLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAIRecommendations();
  }

  Future<void> _loadAIRecommendations() async {
    await _recService.loadModel();
    if (_recService.isReady && _recService.hasUserSelectedGenres()) {
      final recs = _recService.getRecommendations(topN: 15);
      if (mounted) {
        setState(() {
          _aiRecommendations = recs;
          _aiLoaded = true;
        });
      }
    } else {
      if (mounted) setState(() => _aiLoaded = true);
    }
  }

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
      color: HomeScreenColors.refreshColor,
      backgroundColor: HomeScreenColors.refreshBg,
      onRefresh: () async => _refresh(),
      child: CustomScrollView(
        slivers: [
          // REKOMENDASI (Carousel)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // === AI REKOMENDASI (Jika user sudah pilih genre) ===
                if (_aiRecommendations.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFF7C4DFF), size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          "Rekomendasi Untukmu",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C4DFF).withAlpha(40),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "✨ AI",
                            style: TextStyle(color: Color(0xFFB388FF), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Berdasarkan genre: ${_recService.getUserGenres().join(', ')}",
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _aiRecommendations.length,
                      itemBuilder: (context, index) {
                        final rec = _aiRecommendations[index];
                        final manga = Manga(
                          id: rec['manga_id'] ?? '',
                          title: rec['title'] ?? '',
                          image: rec['cover_url'] ?? '',
                          chapter: '',
                          score: (rec['score'] as double?)?.toStringAsFixed(1) ?? '',
                          type: rec['source'] ?? 'shinigami',
                        );
                        return SizedBox(
                          width: 130,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ModernMangaCard(
                              manga: manga,
                              isFeatured: false,
                              sourceMaster: rec['source'] ?? 'shinigami',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
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
                  section: 'latest',
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
                      child: CircularProgressIndicator(color: HomeScreenColors.spinner),
                    ),
                  if (!isLoadingMore && hasMore && onLoadMore != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: ElevatedButton.icon(
                        onPressed: onLoadMore,
                        icon: const Icon(Icons.expand_more),
                        label: const Text('Muat Lebih Banyak'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HomeScreenColors.buttonBg,
                          foregroundColor: HomeScreenColors.buttonText,
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
            style: TextStyle(
              color: HomeScreenColors.sectionTitle,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: HomeScreenColors.filterIcon),
            color: HomeScreenColors.popupBg,
            onSelected: (val) => onSelect(val),
            itemBuilder: (context) => filters.entries
                .map(
                  (e) => PopupMenuItem(
                    value: e.value,
                    child: Text(
                      e.key,
                      style: TextStyle(
                        color: selectedVal == e.value
                            ? HomeScreenColors.filterActive
                            : HomeScreenColors.filterInactive,
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
      color: HomeScreenColors.refreshColor,
      backgroundColor: HomeScreenColors.refreshBg,
      onRefresh: () async => setState(() => _key = UniqueKey()),
      child: CustomScrollView(
        slivers: [
          // POPULAR
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 15),
                  child: Text(
                    "Most Popular ⭐",
                    style: TextStyle(
                      color: HomeScreenColors.sectionTitle,
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 30, 16, 10),
              child: Text(
                "Latest Updates ⚡",
                style: TextStyle(
                  color: HomeScreenColors.sectionTitle,
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
                      child: CircularProgressIndicator(color: HomeScreenColors.spinner),
                    ),
                  if (!isLoadingMore && hasMore && onLoadMore != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: ElevatedButton.icon(
                        onPressed: onLoadMore,
                        icon: const Icon(Icons.expand_more),
                        label: const Text('Muat Lebih Banyak'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HomeScreenColors.buttonBg,
                          foregroundColor: HomeScreenColors.buttonText,
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

class HomeScreenColors {
  static const background      = Color(0xFF121212);    // Background utama & AppBar
  static const fabBg           = Colors.blueAccent;    // Background FAB chatbot
  static const searchIcon      = Colors.white;         // Ikon search di AppBar
  static const avatarBg        = Colors.blueAccent;    // Background avatar profile
  static const avatarIcon      = Colors.white;         // Ikon person di avatar
  static const tabIndicator    = Colors.blueAccent;    // Garis indikator tab aktif
  static const tabActive       = Colors.white;         // Teks tab aktif
  static const tabInactive     = Colors.grey;          // Teks tab tidak aktif
  static const spinner         = Colors.blueAccent;    // Loading spinner
  static const statusText      = Colors.white54;       // Teks status loading/error
  static const errorIcon       = Colors.white24;       // Ikon cloud_off saat error
  static const retryIcon       = Colors.white;         // Ikon refresh di tombol retry
  static const retryText       = Colors.white;         // Teks "Bangunkan Paksa!"
  static const buttonBg        = Colors.blueAccent;    // Background tombol (retry & load more)
  static const buttonText      = Colors.white;         // Teks tombol "Muat Lebih Banyak"
  static const refreshColor    = Colors.blueAccent;    // Warna RefreshIndicator
  static final refreshBg       = Colors.grey[900];     // Background RefreshIndicator
  static const sectionTitle    = Colors.white;         // Judul section (Featured, Latest, Popular)
  static const filterIcon      = Colors.blueAccent;    // Ikon filter
  static final popupBg         = Colors.grey[900];     // Background popup menu filter
  static const filterActive    = Colors.blueAccent;    // Teks filter terpilih
  static const filterInactive  = Colors.white;         // Teks filter tidak terpilih
}
