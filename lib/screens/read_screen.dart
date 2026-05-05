import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../models/manga_detail_model.dart';

class ReadScreen extends StatefulWidget {
  final String source;
  final String mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String chapterId;
  final String chapterTitle;
  // Chapter navigation
  final List<Chapter> chapters;
  final int currentIndex;

  const ReadScreen({
    super.key,
    required this.source,
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.chapterId,
    required this.chapterTitle,
    required this.chapters,
    required this.currentIndex,
  });

  @override
  State<ReadScreen> createState() => _ReadScreenState();
}

class _ReadScreenState extends State<ReadScreen> {
  late Future<List<String>> _imagesFuture;
  final HistoryService _historyService = HistoryService();
  final ScrollController _scrollController = ScrollController();

  bool get hasPrevChapter => widget.currentIndex < widget.chapters.length - 1;
  bool get hasNextChapter => widget.currentIndex > 0;

  @override
  void initState() {
    super.initState();
    _imagesFuture = ApiService().fetchChapterImages(
      source: widget.source,
      chapterId: widget.chapterId,
    );
    _saveToHistory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _saveToHistory() {
    _historyService.addToHistory(
      mangaId: widget.mangaId,
      mangaTitle: widget.mangaTitle,
      mangaCover: widget.mangaCover,
      chapterId: widget.chapterId,
      chapterTitle: widget.chapterTitle,
      source: widget.source,
    );
    _historyService.markChapterAsRead(widget.mangaId, widget.chapterId);
  }

  void _navigateToChapter(int newIndex) {
    final chapter = widget.chapters[newIndex];
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ReadScreen(
          source: widget.source,
          mangaId: widget.mangaId,
          mangaTitle: widget.mangaTitle,
          mangaCover: widget.mangaCover,
          chapterId: chapter.id,
          chapterTitle: chapter.title,
          chapters: widget.chapters,
          currentIndex: newIndex,
        ),
      ),
    );
  }

  void _goToPrevChapter() {
    if (hasPrevChapter) {
      _navigateToChapter(widget.currentIndex + 1);
    }
  }

  void _goToNextChapter() {
    if (hasNextChapter) {
      _navigateToChapter(widget.currentIndex - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReadScreenColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.mangaTitle, style: const TextStyle(fontSize: 14, color: ReadScreenColors.appBarSubtitle)),
            Text(widget.chapterTitle, style: const TextStyle(fontSize: 16)),
          ],
        ),
        backgroundColor: ReadScreenColors.appBarBg,
        foregroundColor: ReadScreenColors.appBarText,
        elevation: 0,
      ),
      body: FutureBuilder<List<String>>(
        future: _imagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: ReadScreenColors.errorText)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Tidak ada gambar.", style: TextStyle(color: ReadScreenColors.emptyText)));
          }

          final images = snapshot.data!;

          return InteractiveViewer(
            minScale: 1.0,
            maxScale: 5.0,
            child: ListView.builder(
              controller: _scrollController,
              cacheExtent: 5000,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.fitWidth,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: ReadScreenColors.placeholderBg,
                    child: const Center(child: CircularProgressIndicator(color: ReadScreenColors.placeholderSpinner)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 100,
                    color: ReadScreenColors.errorImgBg,
                    child: const Icon(Icons.broken_image, color: ReadScreenColors.errorImgIcon),
                  ),
                  httpHeaders: const {
                    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                    "Referer": "https://google.com"
                  },
                );
              },
            ),
          );
        },
      ),
      // Bottom Navigation Bar untuk Prev/Next Chapter
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: ReadScreenColors.navBarBg,
          boxShadow: [
            BoxShadow(
              color: ReadScreenColors.navBarShadow,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Prev Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasPrevChapter ? _goToPrevChapter : null,
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                  label: const Text("Prev"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasPrevChapter ? ReadScreenColors.btnActive : ReadScreenColors.btnDisabledBg,
                    foregroundColor: hasPrevChapter ? ReadScreenColors.btnActiveText : ReadScreenColors.btnDisabledText,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Next Button  
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasNextChapter ? _goToNextChapter : null,
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  label: const Text("Next"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasNextChapter ? ReadScreenColors.btnActive : ReadScreenColors.btnDisabledBg,
                    foregroundColor: hasNextChapter ? ReadScreenColors.btnActiveText : ReadScreenColors.btnDisabledText,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== COLOR SETTINGS ====================
class ReadScreenColors {
  static const background         = Colors.black;           // Background utama
  static final appBarBg            = Colors.black.withOpacity(0.8); // Background AppBar
  static const appBarText          = Colors.white;           // Teks judul chapter
  static const appBarSubtitle      = Colors.grey;            // Teks nama manga di AppBar
  static const errorText           = Colors.white;           // Teks error
  static const emptyText           = Colors.white;           // Teks "Tidak ada gambar"
  static final placeholderBg       = Colors.grey[900];       // Background placeholder loading
  static const placeholderSpinner  = Colors.grey;            // Spinner placeholder
  static final errorImgBg          = Colors.grey[900];       // Background error gambar
  static const errorImgIcon        = Colors.red;             // Ikon broken_image
  static final navBarBg            = Colors.grey[900];       // Background navbar bawah
  static final navBarShadow        = Colors.black.withOpacity(0.5); // Shadow navbar
  static const btnActive           = Colors.blue;            // Background tombol Prev/Next aktif
  static const btnActiveText       = Colors.white;           // Teks tombol aktif
  static final btnDisabledBg       = Colors.grey[800];       // Background tombol disabled
  static final btnDisabledText     = Colors.grey[600];       // Teks tombol disabled
}