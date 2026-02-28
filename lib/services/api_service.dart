import 'package:dio/dio.dart';
import '../models/manga_model.dart';
import '../models/manga_detail_model.dart';

class ApiService {
  // 1. URL KOMIKINDO API (Custom)
  static const String komikindoUrl = 'https://rex4red-api-komikindo.hf.space';
  
  // 2. URL SHINIGAMI API (Custom)
  static const String shinigamiUrl = 'https://rex4red-shinigami-api.hf.space';

  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30), 
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        "User-Agent": "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
        "Accept": "application/json",
      },
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
    // 🚀 SHINIGAMI: Langsung ke Sansekai API (skip HuggingFace yg lambat)
    if (source == 'shinigami') {
      return await _fetchShinigamiListDirect(section: section, type: type, query: query);
    }

    // KOMIKINDO: Pakai API baru (api-komikindo.rex4red.my.id)
    try {
      String endpoint;
      Map<String, dynamic> params = {};

      if (query.isNotEmpty) {
        // Search mode
        endpoint = '$komikindoUrl/komik/search';
        params = {'q': query};
      } else if (section == 'popular') {
        endpoint = '$komikindoUrl/komik/popular';
        params = {'page': 1};
      } else {
        // Default: latest
        endpoint = '$komikindoUrl/komik/latest';
        params = {'page': 1};
      }

      final response = await _dio.get(endpoint, queryParameters: params);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'];
        if (data.isNotEmpty) {
          return data.map((json) => Manga.fromJson(json, source)).toList();
        }
      }
      return [];
    } catch (e) {
      print("❌ List Error [$source]: $e");
      return []; 
    }
  }

  // 🚀 FETCH LIST SHINIGAMI LANGSUNG DARI SANSEKAI (cepat, ~2ms)
  Future<List<Manga>> _fetchShinigamiListDirect({
    String section = 'latest',
    String? type,
    String query = '',
  }) async {
    try {
      // Search mode
      if (query.isNotEmpty) {
        final response = await _dio.get('$shinigamiUrl/komik/search', 
          queryParameters: {'query': query});
        if (response.statusCode == 200 && response.data['retcode'] == 0) {
          return _mapSansekaiListToManga(response.data['data']);
        }
        return [];
      }

      // List mode (latest / recommended)
      final Map<String, dynamic> params = {};
      if (type != null && type.isNotEmpty) params['type'] = type;

      final String endpoint = section == 'recommended' 
          ? '$shinigamiUrl/komik/recommended' 
          : '$shinigamiUrl/komik/latest';

      final response = await _dio.get(endpoint, queryParameters: params);

      if (response.statusCode == 200 && response.data['retcode'] == 0) {
        return _mapSansekaiListToManga(response.data['data']);
      }
    } catch (e) {
      print("❌ [Sansekai Direct] Error: $e");
    }
    return [];
  }

  // Helper: Map Sansekai list data → Manga model
  List<Manga> _mapSansekaiListToManga(List<dynamic> data) {
    return data.map((json) => Manga(
      id: json['manga_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Tanpa Judul',
      image: json['cover_image_url'] ?? json['cover_portrait_url'] ?? '',
      chapter: json['latest_chapter_number'] != null 
          ? 'Ch. ${json['latest_chapter_number']}' 
          : 'Ch. ?',
      score: json['user_rate']?.toString() ?? 'N/A',
      type: 'shinigami',
    )).toList();
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
          print("⚠️ Shinigami Direct Gagal: $e");
          rethrow; // Server proxy lama sudah down
        }
      } else {
        // KomikIndo: langsung ke API baru
        return await _fetchKomikindoDirect(id);
      }
    } catch (e) {
      print("❌ Detail Error Final: $e");
      rethrow;
    }
  }

  // --- LOGIC FETCH KOMIKINDO DIRECT ---
  Future<MangaDetail> _fetchKomikindoDirect(String id) async {
    // Bersihkan id: hapus prefix /komik/ dan trailing slash
    String cleanId = id;
    if (cleanId.contains('page=manga&id=')) {
      cleanId = cleanId.split('id=').last;
    }
    if (cleanId.startsWith('/komik/')) cleanId = cleanId.replaceFirst('/komik/', '');
    if (cleanId.startsWith('/')) cleanId = cleanId.substring(1);
    if (cleanId.endsWith('/')) cleanId = cleanId.substring(0, cleanId.length - 1);

    print("🌐 [Komikindo] Mengakses: $komikindoUrl/komik/detail/$cleanId");
    final response = await _dio.get('$komikindoUrl/komik/detail/$cleanId');
    
    if (response.statusCode == 200) {
        var rawData = response.data;
        if (rawData['success'] == true && rawData['data'] != null) {
          return _mapKomikIndoToModel(rawData['data']);
        } else {
          throw Exception("API Error: ${rawData['error'] ?? 'Unknown'}");
        }
    } else {
      throw Exception("Server Error Code: ${response.statusCode}");
    }
  }

  // --- LOGIC SHINIGAMI DIRECT (HP) ---
  Future<MangaDetail> _fetchShinigamiDirect(String rawId) async {
    String cleanId = rawId.replaceFirst('manga-', '');
    if (cleanId.contains('http')) cleanId = cleanId.split('/').last;

    // 🔥 SAFE GET: Coba detail + chapters sekaligus via custom API
    final results = await Future.wait([
      _safeGet('$shinigamiUrl/komik/detail/$cleanId', {}),
      _safeGet('$shinigamiUrl/komik/detail/manga-$cleanId', {}),
      _safeGet('$shinigamiUrl/komik/$cleanId/chapters', {})
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
    if (data['chapters'] is List) {
      rawChapters = data['chapters'];
    } else if (data['chapter_list'] is List) rawChapters = data['chapter_list'];
    else if (data['list_chapter'] is List) rawChapters = data['list_chapter'];
    // API baru: data langsung berupa list (nested 'data' sudah di-unwrap)
    else if (data['data'] is List) rawChapters = data['data'];

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
      // Extract chapter ID dari berbagai format
      String rawId = ch['id']?.toString() ?? ch['endpoint']?.toString() ?? '';
      
      // API baru: ID ada di url query param (?page=chapter&id=404041)
      if (rawId.isEmpty && ch['url'] != null) {
        final url = ch['url'].toString();
        final uri = Uri.tryParse(url);
        if (uri != null && uri.queryParameters.containsKey('id')) {
          rawId = uri.queryParameters['id']!;
        }
      }
      
      if (rawId.startsWith('/')) rawId = rawId.substring(1); 
      if (rawId.contains('http')) {
         if (rawId.endsWith('/')) rawId = rawId.substring(0, rawId.length - 1);
         rawId = rawId.split('/').last;
      }

      // Title: bisa dari 'title', 'name', atau construct dari 'chapter' field
      String chTitle = ch['title']?.toString() ?? ch['name']?.toString() ?? '';
      if (chTitle.isEmpty && ch['chapter'] != null) {
        chTitle = 'Chapter ${ch['chapter']}';
      }
      if (chTitle.isEmpty) chTitle = 'Chapter ?';

      return Chapter(
        title: chTitle, 
        id: rawId, 
        date: ch['date']?.toString() ?? ch['time']?.toString() ?? ''
      );
    }).toList();

    return MangaDetail(
      title: data['title']?.toString() ?? 'Tanpa Judul',
      cover: data['cover']?.toString() ?? data['img']?.toString() ?? data['image']?.toString() ?? data['thumb']?.toString() ?? '',
      synopsis: data['synopsis']?.toString() ?? 'Tidak ada sinopsis',
      author: data['author']?.toString() ?? 'Unknown',
      status: data['status']?.toString() ?? 'Unknown',
      chapters: finalChapters,
    );
  }

  // --- 3. AMBIL GAMBAR CHAPTER ---
  Future<List<String>> fetchChapterImages({required String source, required String chapterId}) async {
    try {
      // 🚀 Shinigami: langsung ke custom API
      if (source == 'shinigami') {
        final response = await _dio.get('$shinigamiUrl/chapter/$chapterId');
        if (response.statusCode == 200 && response.data['retcode'] == 0) {
          final chapterData = response.data['data'];
          final String baseUrl = chapterData['base_url'] ?? '';
          final String path = chapterData['chapter']?['path'] ?? '';
          final List filenames = chapterData['chapter']?['data'] ?? [];
          return filenames.map((f) => '$baseUrl$path$f').toList().cast<String>();
        }
      }

      // KomikIndo: via API baru
      String cleanChapterId = chapterId;
      if (cleanChapterId.contains('page=chapter&id=')) {
        cleanChapterId = cleanChapterId.split('id=').last;
      }
      final response = await _dio.get('$komikindoUrl/chapter/$cleanChapterId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null && data is Map) {
          // API response: data.image = [url1, url2, ...]
          final images = data['image'];
          if (images != null && images is List) {
            return List<String>.from(images);
          }
        }
        // Fallback: coba langsung di root
        if (response.data['images'] != null && response.data['images'] is List) {
          return List<String>.from(response.data['images']);
        }
      }
      return [];
    } catch (e) {
      print("❌ ChapterImages Error [$source]: $e");
      return [];
    }
  }
}
