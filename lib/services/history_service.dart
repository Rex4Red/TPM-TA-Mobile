import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==========================================
  // BAGIAN 1: RIWAYAT BACA (LAST READ)
  // Digunakan untuk menampilkan list di menu "Riwayat Baca"
  // ==========================================

  // Fungsi Simpan / Update History (Upsert)
  Future<void> addToHistory({
    required String mangaId,
    required String mangaTitle,
    required String mangaCover,
    required String chapterId,
    required String chapterTitle,
    required String source,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return; // Kalau belum login, gak usah simpan

    try {
      // Menggunakan upsert: Jika manga_id sudah ada, update chapter terakhir & waktu.
      // Jika belum ada, buat baru.
      await _supabase.from('history').upsert({
        'user_id': user.id,
        'manga_id': mangaId,
        'manga_title': mangaTitle,
        'manga_cover': mangaCover,
        'chapter_id': chapterId,
        'chapter_title': chapterTitle,
        'source': source,
        'last_read_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, manga_id'); 
    } catch (e) {
      print("Gagal menyimpan history: $e");
    }
  }

  // Fungsi Ambil List History
  Future<List<Map<String, dynamic>>> fetchHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('history')
          .select()
          .order('last_read_at', ascending: false); // Urutkan dari yang terakhir dibaca
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Gagal mengambil history: $e");
      return [];
    }
  }

  // ==========================================
  // BAGIAN 2: PENANDA CHAPTER (READ MARKER)
  // Digunakan untuk mengubah warna tombol chapter jadi biru
  // ==========================================

  // Fungsi Tandai Chapter Tertentu sebagai "Sudah Dibaca"
  Future<void> markChapterAsRead(String mangaId, String chapterId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Simpan ke tabel 'chapter_reads'.
      // Gunakan upsert agar jika sudah ada, tidak error (idempotent)
      await _supabase.from('chapter_reads').upsert(
        {
          'user_id': user.id,
          'manga_id': mangaId,
          'chapter_id': chapterId,
          'read_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id, manga_id, chapter_id', // Pastikan constraint unik ini ada di SQL Supabase
      );
    } catch (e) {
      print("Gagal menandai chapter read: $e");
    }
  }

  // Fungsi Ambil Daftar ID Chapter yang Sudah Dibaca (Untuk Detail Screen)
  Future<List<String>> getReadChapterIds(String mangaId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('chapter_reads')
          .select('chapter_id')
          .eq('user_id', user.id)
          .eq('manga_id', mangaId);
      
      // Mapping hasil JSON dari Supabase menjadi List<String> biasa
      final List<dynamic> data = response as List<dynamic>;
      return data.map((e) => e['chapter_id'] as String).toList();
    } catch (e) {
      print("Gagal ambil data chapter read: $e");
      return [];
    }
  }
}