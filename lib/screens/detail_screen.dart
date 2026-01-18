import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../models/manga_detail_model.dart';
import 'read_screen.dart'; 
import '../services/bookmark_service.dart'; 

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
  
  // --- VARIABEL UNTUK BOOKMARK ---
  bool _isBookmarked = false; 
  final BookmarkService _bookmarkService = BookmarkService();

  @override
  void initState() {
    super.initState();
    // 1. Ambil data detail komik
    _detail = ApiService().fetchMangaDetail(source: widget.source, id: widget.mangaId);
    
    // 2. Cek apakah komik ini sudah ada di favorit user?
    _checkBookmarkStatus();
  }

  // Fungsi Cek Status Bookmark di Database
  void _checkBookmarkStatus() async {
    try {
      final status = await _bookmarkService.isBookmarked(widget.source, widget.mangaId);
      if (mounted) {
        setState(() {
          _isBookmarked = status;
        });
      }
    } catch (e) {
      print("Bookmark Check Error: $e");
    }
  }

  // Fungsi Saat Tombol Love Ditekan
  void _onBookmarkPressed() async {
    try {
      // 1. Ambil data detail yang sudah di-load (tunggu jika belum selesai)
      final data = await _detail;

      // 2. Ambil Chapter Terbaru (Biasanya index ke-0 adalah yang paling baru)
      String latestChapter = "Chapter -";
      if (data.chapters.isNotEmpty) {
        latestChapter = data.chapters.first.title;
      }

      // 3. Update UI Optimistic
      setState(() => _isBookmarked = !_isBookmarked); 
      
      // 4. Simpan ke Database dengan info Last Chapter
      final newStatus = await _bookmarkService.toggleBookmark(
        source: widget.source,
        mangaId: widget.mangaId,
        title: widget.title,
        cover: widget.cover,
        latestChapter: latestChapter, // <--- DATA BARU DIKIRIM KE SINI
      );

      // 5. Sinkronisasi status
      if (mounted) setState(() => _isBookmarked = newStatus);

      // --- LOGIKA NOTIFIKASI ---
      if (newStatus == true) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null && user.email != null) {
           // Ambil settingan notifikasi user
           final settings = await Supabase.instance.client
               .from('user_settings')
               .select()
               .eq('user_id', user.id)
               .maybeSingle();
           
           // Kirim notifikasi
           ApiService().sendNotification(
             title: widget.title, 
             cover: widget.cover, 
             userEmail: user.email!, 
             isAdded: true,
             discordWebhook: settings?['discord_webhook'],      
             telegramToken: settings?['telegram_bot_token'],    
             telegramChatId: settings?['telegram_chat_id'],     
           );
        }
      }
      // -----------------------------

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
      // Error Handling
      print("Error Bookmark: $e");
      if (mounted) setState(() => _isBookmarked = !_isBookmarked);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal! Pastikan kamu sudah Login."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      
      // 👇 TOMBOL LOVE MELAYANG (FAB)
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

          final data = snapshot.data!;

          return CustomScrollView(
            slivers: [
              // 1. HEADER (SLIVER APP BAR)
              SliverAppBar(
                expandedHeight: 300.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.grey[900],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    data.title.length > 20 ? "${data.title.substring(0, 20)}..." : data.title,
                    style: const TextStyle(fontSize: 16, shadows: [Shadow(blurRadius: 10, color: Colors.black)]),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Buram
                      CachedNetworkImage(
                        imageUrl: data.cover,
                        fit: BoxFit.cover,
                        color: Colors.black.withOpacity(0.6),
                        colorBlendMode: BlendMode.darken,
                        httpHeaders: const {"Referer": "https://google.com", "User-Agent": "Mozilla/5.0"},
                      ),
                      // Gambar Utama
                      Center(
                        child: Container(
                          height: 200,
                          width: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 10)],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                                imageUrl: data.cover, fit: BoxFit.cover,
                                httpHeaders: const {"Referer": "https://google.com", "User-Agent": "Mozilla/5.0"},
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
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: Text(chapter.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                        onTap: () {
                           // Navigasi ke Layar Baca
                           Navigator.push(
                             context,
                             MaterialPageRoute(
                               builder: (context) => ReadScreen(
                                 source: widget.source,
                                 chapterId: chapter.id,
                                 chapterTitle: chapter.title,
                               ),
                             ),
                           );
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