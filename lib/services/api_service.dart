import 'package:dio/dio.dart';
import '../models/manga_model.dart';
import '../models/manga_detail_model.dart';

class ApiService {
  // 1. URL SERVER KITA
  static const String serverUrl = 'https://rex4red-rex4red-komik-api-scrape.hf.space/api/mobile';
  
  // 2. URL LANGSUNG SANSEKAI
  static const String sansekaiUrl = 'https://api.sansekai.my.id/api';

  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 60), 
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        // User Agent Chrome Terbaru (Penting!)
        "User-Agent": "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
        "Accept": "application/json",
      },
      // 🔥 TERIMA SEMUA STATUS (JANGAN CRASH DULU KALAU 500) 🔥
      validateStatus: (status) => true, 
    ));
  }

  // --- 1. AMBIL LIST MANGA ---
  Future<List<Manga>> fetchMangaList({
    String source = 'shinigami', 
    String query = '',
    String section = 'latest', 
    String? type, 
  }) async {
    try {
      final Map<String, dynamic> params = {
        'source': source,
        'q': query.isNotEmpty ? query : null,
        'section': section,
      };
      if (type != null && type.isNotEmpty) params['type'] = type;

      final response = await _dio.get('$serverUrl/list', queryParameters: params);

      if (response.statusCode == 200 && response.data['status'] == true) {
        final List data = response.data['data'];
        return data.map((json) => Manga.fromJson(json, source)).toList();
      }
      return [];
    } catch (e) {
      print("❌ List Error: $e");
      return []; 
    }
  }

  // --- 2. AMBIL DETAIL MANGA (SYSTEM FALLBACK) ---
  Future<MangaDetail> fetchMangaDetail({required String source, required String id}) async {
    try {
      if (source == 'shinigami') {
        print("🚀 [1/2] Mencoba Shinigami Direct: $id");
        try {
          // COBA 1: DIRECT DARI HP
          return await _fetchShinigamiDirect(id);
        } catch (e) {
          print("⚠️ Direct Gagal ($e). Beralih ke Server Proxy...");
          // COBA 2: LEWAT SERVER (FALLBACK)
          return await _fetchViaServer(source, id);
        }
      } else {
        // KomikIndo langsung lewat server
        return await _fetchViaServer(source, id);
      }
    } catch (e) {
      print("❌ Detail Error Final: $e");
      rethrow;
    }
  }

  // --- LOGIC FETCH VIA SERVER (NEXT.JS) ---
  Future<MangaDetail> _fetchViaServer(String source, String id) async {
    print("🌐 [2/2] Mengakses via Server: $id");
    final response = await _dio.get(
      '$serverUrl/komik/detail', 
      queryParameters: {'source': source, 'id': id}
    );
    
    if (response.statusCode == 200) {
        var rawData = response.data;
        if (rawData['status'] == true && rawData['data'] != null) {
          // Deteksi sumber untuk mapping yang tepat
          if (source == 'shinigami' || (rawData['source'] == 'Shinigami')) {
             return _mapSansekaiToModel(rawData['data'], []); // Data server biasanya sudah lengkap
          } else {
             return _mapKomikIndoToModel(rawData['data']);
          }
        } else {
          throw Exception("Server Message: ${rawData['message']}");
        }
    } else {
      throw Exception("Server Error Code: ${response.statusCode}");
    }
  }

  // --- LOGIC SHINIGAMI DIRECT (HP) ---
  Future<MangaDetail> _fetchShinigamiDirect(String rawId) async {
    String cleanId = rawId.replaceFirst('manga-', '');
    if (cleanId.contains('http')) cleanId = cleanId.split('/').last;

    // 🔥 SAFE GET: Coba beberapa endpoint sekaligus tanpa throw error 500
    final results = await Future.wait([
      _safeGet('$sansekaiUrl/komik/detail', {'manga_id': cleanId}),
      _safeGet('$sansekaiUrl/komik/detail', {'manga_id': 'manga-$cleanId'}),
      _safeGet('$sansekaiUrl/komik/chapterlist', {'manga_id': cleanId})
    ]);

    var resDetail = results[0];
    if (resDetail?.statusCode != 200 || resDetail?.data['data'] == null) {
      resDetail = results[1]; // Coba yang pakai 'manga-'
    }

    var resChapters = results[2];

    // Cek apakah berhasil
    if (resDetail != null && resDetail.statusCode == 200 && resDetail.data['data'] != null) {
      List<dynamic> chapterData = [];
      
      // Ambil chapter dari endpoint chapterlist (prioritas)
      if (resChapters != null && resChapters.statusCode == 200 && resChapters.data['data'] != null) {
          chapterData = resChapters.data['data'];
      } 
      // Atau dari detail (fallback)
      else if (resDetail.data['data']['chapters'] != null) {
          chapterData = resDetail.data['data']['chapters'];
      }

      return _mapSansekaiToModel(resDetail.data['data'], chapterData);
    } 
    
    // Kalau sampai sini berarti Direct Gagal Total
    throw Exception("Gagal Direct Hit");
  }

  // Helper Request Aman
  Future<Response?> _safeGet(String url, Map<String, dynamic> params) async {
    try {
      return await _dio.get(url, queryParameters: params);
    } catch (e) { return null; }
  }

  // --- MAPPING SHINIGAMI ---
  MangaDetail _mapSansekaiToModel(Map<String, dynamic> detail, List<dynamic> chapters) {
    String statusStr = 'Unknown';
    if (detail['status'] != null) {
      if (detail['status'] == 1) {
        statusStr = 'Ongoing';
      } else if (detail['status'] == 0) statusStr = 'Completed';
      else statusStr = detail['status'].toString();
    }

    String synopsisStr = detail['synopsis']?.toString() ?? detail['description']?.toString() ?? 'Tidak ada sinopsis';
    String authorStr = detail['author']?.toString() ?? detail['authors']?.toString() ?? 'Unknown';

    // Gabungkan chapter external (jika ada) atau internal
    List<dynamic> finalRawChapters = chapters.isNotEmpty ? chapters : (detail['chapters'] ?? []);

    List<Chapter> finalChapters = finalRawChapters.map((ch) {
      return Chapter(
        title: "Chapter ${ch['chapter_number']?.toString() ?? '?'}", 
        id: (ch['chapter_id'] ?? ch['id'] ?? ch['endpoint'] ?? ch['href'] ?? '').toString(), 
        date: ch['release_date']?.toString() ?? ''
      );
    }).toList();

    return MangaDetail(
      title: detail['title']?.toString() ?? 'Tanpa Judul',
      cover: detail['thumbnail']?.toString() ?? detail['cover_image_url']?.toString() ?? '',
      synopsis: synopsisStr,
      author: authorStr, 
      status: statusStr,
      chapters: finalChapters,
    );
  }

  // --- MAPPING KOMIKINDO ---
  MangaDetail _mapKomikIndoToModel(Map<String, dynamic> data) {
    List<dynamic> rawChapters = [];
    if (data['chapters'] != null && data['chapters'] is List) {
      rawChapters = data['chapters'];
    } else if (data['chapter_list'] != null && data['chapter_list'] is List) rawChapters = data['chapter_list'];
    else if (data['list_chapter'] != null && data['list_chapter'] is List) rawChapters = data['list_chapter'];

    // Backup Plan
    if (rawChapters.isEmpty) {
      for (var key in data.keys) {
        if (data[key] is List && (data[key] as List).isNotEmpty) {
          rawChapters = data[key];
          break; 
        }
      }
    }

    List<Chapter> finalChapters = rawChapters.map((ch) {
      String rawId = ch['id']?.toString() ?? ch['endpoint']?.toString() ?? '';
      if (rawId.startsWith('/')) rawId = rawId.substring(1); 
      if (rawId.contains('http')) {
         if (rawId.endsWith('/')) rawId = rawId.substring(0, rawId.length - 1);
         rawId = rawId.split('/').last;
      }

      return Chapter(
        title: ch['title']?.toString() ?? ch['name']?.toString() ?? 'Chapter ?', 
        id: rawId, 
        date: ch['date']?.toString() ?? ''
      );
    }).toList();

    return MangaDetail(
      title: data['title']?.toString() ?? 'Tanpa Judul',
      cover: data['cover']?.toString() ?? data['image']?.toString() ?? data['thumb']?.toString() ?? '',
      synopsis: data['synopsis']?.toString() ?? 'Tidak ada sinopsis',
      author: data['author']?.toString() ?? 'Unknown',
      status: data['status']?.toString() ?? 'Unknown',
      chapters: finalChapters,
    );
  }

  // --- 3. AMBIL GAMBAR CHAPTER ---
  Future<List<String>> fetchChapterImages({required String source, required String chapterId}) async {
    try {
      final response = await _dio.get(
        '$serverUrl/chapter', 
        queryParameters: {'source': source, 'id': chapterId}
      );
      if (response.statusCode == 200 && response.data['status'] == true) {
        return List<String>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- 4. NOTIFIKASI ---
  Future<void> sendNotification({
    required String title,
    required String cover,
    required String userEmail,
    required bool isAdded,
    String? discordWebhook,
    String? telegramToken,
    String? telegramChatId,
  }) async {

    final statusText = isAdded ? "Ditambahkan ke Favorit ❤️" : "Dihapus dari Favorit 💔";
    final message = "User: $userEmail\nAction: $statusText\nManga: $title";

    if (discordWebhook != null && discordWebhook.isNotEmpty) {
      try {
        await _dio.post(discordWebhook, data: {
          "content": message,
          "embeds": [{"title": title, "description": statusText, "color": isAdded ? 5763719 : 15548997, "image": {"url": cover}}]
        });
      } catch (e) {}
    }

    if (telegramToken != null && telegramChatId != null && telegramToken.isNotEmpty) {
      try {
        await _dio.post("https://api.telegram.org/bot$telegramToken/sendMessage", 
          data: {"chat_id": telegramChatId, "text": "$message\n$cover"});
      } catch (e) {}
    }
  }
}