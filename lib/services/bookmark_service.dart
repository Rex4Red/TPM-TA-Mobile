import 'package:supabase_flutter/supabase_flutter.dart';

class BookmarkService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. Cek apakah komik ini sudah difavoritkan?
  Future<bool> isBookmarked(String source, String mangaId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final data = await _supabase
        .from('bookmarks')
        .select()
        .eq('user_id', user.id)
        .eq('source', source)
        .eq('manga_id', mangaId)
        .maybeSingle(); // Mengambil satu data jika ada

    return data != null;
  }

  // 2. Tambah/Hapus Favorit (Toggle)
  // Tambahkan parameter 'latestChapter'
  Future<bool> toggleBookmark({
    required String source,
    required String mangaId,
    required String title,
    required String cover,
    required String latestChapter, // <--- PARAMETER BARU
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Harus login dulu!");

    final isExist = await isBookmarked(source, mangaId);

    if (isExist) {
      await _supabase
          .from('bookmarks')
          .delete()
          .eq('user_id', user.id)
          .eq('source', source)
          .eq('manga_id', mangaId);
      return false; 
    } else {
      await _supabase.from('bookmarks').insert({
        'user_id': user.id,
        'source': source,
        'manga_id': mangaId,
        'title': title,
        'cover': cover,
        'last_chapter': latestChapter, // <--- SIMPAN DI SINI
      });
      return true; 
    }
  }

  // 3. Ambil Semua Daftar Favorit User
  Future<List<Map<String, dynamic>>> getBookmarks() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final data = await _supabase
        .from('bookmarks')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }
}