import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../models/manga_detail_model.dart';
import '../services/bookmark_service.dart';
import '../services/history_service.dart'; // Pastikan ada
import 'read_screen.dart'; // Pastikan ada

class DetailScreen extends StatefulWidget {
  final String source;
  final String mangaId;
  final String title;
  final String cover;

  const DetailScreen({
    super.key,
    required this.source,
    required this.mangaId,
    required this.title,
    required this.cover,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Future<MangaDetail> _detail;
  
  // Service
  final BookmarkService _bookmarkService = BookmarkService();
  final HistoryService _historyService = HistoryService();
  
  bool _isBookmarked = false;
  Set<String> _readChapterIds = {};

  @override
  void initState() {
    super.initState();
    // 1. Load Detail
    _detail = ApiService().fetchMangaDetail(source: widget.source, id: widget.mangaId);
    
    // 2. Cek Bookmark & History
    _checkBookmarkStatus();
    _fetchReadChapters();
  }

  void _checkBookmarkStatus() async {
    try {
      final status = await _bookmarkService.isBookmarked(widget.source, widget.mangaId);
      if (mounted) setState(() => _isBookmarked = status);
    } catch (e) {
      print("Bookmark Check Error: $e");
    }
  }

  void _fetchReadChapters() async {
    try {
      final ids = await _historyService.getReadChapterIds(widget.mangaId);
      if (mounted) setState(() => _readChapterIds = ids.toSet());
    } catch (e) {
      print("History Check Error: $e");
    }
  }

  // 🔥 FUNGSI UTAMA: BOOKMARK & NOTIFIKASI 🔥
  void _onBookmarkPressed() async {
    final user = Supabase.instance.client.auth.currentUser;

    // 1. Cek Login
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan Login untuk menyimpan favorit!")),
      );
      return;
    }

    try {
      // 2. Optimistic Update (Ubah UI duluan biar cepat)
      setState(() => _isBookmarked = !_isBookmarked);

      // 3. Ambil data detail (untuk dapat chapter terakhir)
      final data = await _detail;
      String latestChapter = data.chapters.isNotEmpty ? data.chapters.first.title : "Chapter -";

      // 4. Simpan ke Database Lokal/Supabase (Bookmark Service)
      final newStatus = await _bookmarkService.toggleBookmark(
        source: widget.source,
        mangaId: widget.mangaId,
        title: widget.title,
        cover: widget.cover,
        latestChapter: latestChapter,
      );

      // 5. Sinkronkan status UI
      if (mounted) setState(() => _isBookmarked = newStatus);

      // 6. 🔥 LOGIKA KIRIM NOTIFIKASI 🔥
      if (newStatus == true) { // Hanya kirim notif saat DITAMBAHKAN
        _sendNotificationToUser(user.id, user.email ?? "User");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? "Ditambahkan ke Favorit ❤️" : "Dihapus dari Favorit 💔"),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.grey[900],
          ),
        );
      }

    } catch (e) {
      print("Bookmark Error: $e");
      if (mounted) setState(() => _isBookmarked = !_isBookmarked); // Rollback jika error
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    }
  }

  // Fungsi Terpisah untuk Ambil Setting & Kirim Notif
  Future<void> _sendNotificationToUser(String userId, String userEmail) async {
    try {
      // A. Ambil Settingan User dari Supabase
      final settings = await Supabase.instance.client
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (settings != null) {
        // Ambil token, jika isinya "EMPTY" anggap null
        String? discord = settings['discord_webhook'];
        if (discord == "EMPTY" || discord == "") discord = null;

        String? tgToken = settings['telegram_bot_token'];
        if (tgToken == "EMPTY" || tgToken == "") tgToken = null;

        String? tgChatId = settings['telegram_chat_id'];
        if (tgChatId == "EMPTY" || tgChatId == "") tgChatId = null;

        // B. Panggil API Service untuk kirim notif
        await ApiService().sendNotification(
          title: widget.title,
          cover: widget.cover,
          userEmail: userEmail,
          isAdded: true,
          discordWebhook: discord,
          telegramToken: tgToken,
          telegramChatId: tgChatId,
        );
        print("Notifikasi dikirim ke ApiService");
      } else {
        print("User settings tidak ditemukan.");
      }
    } catch (e) {
      print("Gagal kirim notifikasi: $e");
    }
  }

  // Helper untuk Header Gambar
  Map<String, String> _getHeaders(String source) {
    if (source == 'shinigami') {
      return {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Referer": "https://shinigami.id/"
      };
    }
    return {
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
      "Referer": "https://komikindo.tv/"
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        onPressed: _onBookmarkPressed,
        backgroundColor: Colors.grey[900],
        child: Icon(
          _isBookmarked ? Icons.favorite : Icons.favorite_border,
          color: _isBookmarked ? Colors.redAccent : Colors.white,
        ),
      ),
      body: FutureBuilder<MangaDetail>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Data tidak ditemukan", style: TextStyle(color: Colors.white)));
          }

          final data = snapshot.data!;

          return CustomScrollView(
            slivers: [
              // 1. HEADER GAMBAR
              SliverAppBar(
                expandedHeight: 300.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.grey[900],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    data.title.length > 20 ? "${data.title.substring(0, 20)}..." : data.title,
                    style: const TextStyle(fontSize: 14, shadows: [Shadow(blurRadius: 10, color: Colors.black)]),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Blur
                      CachedNetworkImage(
                        imageUrl: widget.cover, // Pakai widget.cover biar aman kalau API detail belum load
                        fit: BoxFit.cover,
                        httpHeaders: _getHeaders(widget.source),
                        color: Colors.black.withOpacity(0.6),
                        colorBlendMode: BlendMode.darken,
                      ),
                      // Gambar Utama
                      Center(
                        child: Container(
                          height: 200, width: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 15)],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: widget.cover,
                              httpHeaders: _getHeaders(widget.source),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. INFO & SINOPSIS
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.person, "Author", data.author),
                      _buildInfoRow(Icons.info, "Status", data.status),
                      const SizedBox(height: 20),
                      const Text("Sinopsis", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(data.synopsis, style: const TextStyle(color: Colors.white70, height: 1.5)),
                      const SizedBox(height: 24),
                      const Text("Daftar Chapter", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              // 3. LIST CHAPTER
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final chapter = data.chapters[index];
                    final isRead = _readChapterIds.contains(chapter.id);

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isRead ? Colors.blue.withOpacity(0.1) : Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                        border: isRead ? Border.all(color: Colors.blue.withOpacity(0.3)) : null,
                      ),
                      child: ListTile(
                        title: Text(
                          chapter.title, 
                          style: TextStyle(
                            color: isRead ? Colors.blueAccent : Colors.white,
                            fontWeight: isRead ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        trailing: Icon(
                          isRead ? Icons.check_circle : Icons.arrow_forward_ios, 
                          color: isRead ? Colors.blueAccent : Colors.grey, 
                          size: 16
                        ),
                        onTap: () async {
                           // Navigasi ke Baca
                           await Navigator.push(
                             context,
                             MaterialPageRoute(
                               builder: (context) => ReadScreen(
                                 source: widget.source,
                                 chapterId: chapter.id,
                                 chapterTitle: chapter.title,
                                 // Data untuk history
                                 mangaId: widget.mangaId,
                                 mangaTitle: widget.title,
                                 mangaCover: widget.cover,
                               ),
                             ),
                           );
                           // Refresh history setelah baca
                           _fetchReadChapters();
                        },
                      ),
                    );
                  },
                  childCount: data.chapters.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)), 
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}