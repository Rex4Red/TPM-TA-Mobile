import 'package:dio/dio.dart';
import '../models/manga_model.dart';
import '../models/manga_detail_model.dart';

class ApiService {
  // URL Vercel (Production)
  static const String baseUrl = 'https://project-web-manga-rex4red.vercel.app/api/mobile';

  final Dio _dio = Dio();

  // --- 1. AMBIL LIST MANGA (HOME & SEARCH) ---
  Future<List<Manga>> fetchMangaList({
    String source = 'shinigami', 
    String query = '',
    String section = 'latest', // 'recommended' atau 'latest'
    String? type,              // 'manhwa', 'project', dll (Optional)
  }) async {
    try {
      final Map<String, dynamic> params = {
        'source': source,
        'q': query.isNotEmpty ? query : null,
        'section': section,
      };

      // Hanya kirim type jika ada isinya
      if (type != null && type.isNotEmpty) {
        params['type'] = type;
      }

      final response = await _dio.get(
        '$baseUrl/list',
        queryParameters: params,
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        final List data = response.data['data'];
        return data.map((json) => Manga.fromJson(json)).toList();
      } else {
        throw Exception('Gagal load data list');
      }
    } catch (e) {
      print("❌ Error Fetching List: $e");
      rethrow;
    }
  }

  // --- 2. AMBIL DETAIL MANGA ---
  Future<MangaDetail> fetchMangaDetail({required String source, required String id}) async {
    try {
      final response = await _dio.get('$baseUrl/detail', queryParameters: {'source': source, 'id': id});
      if (response.statusCode == 200 && response.data['status'] == true) {
        return MangaDetail.fromJson(response.data['data']);
      } else {
        throw Exception('Gagal load data detail');
      }
    } catch (e) {
      rethrow;
    }
  }

  // --- 3. AMBIL GAMBAR CHAPTER ---
  Future<List<String>> fetchChapterImages({required String source, required String chapterId}) async {
    try {
      final response = await _dio.get('$baseUrl/chapter', queryParameters: {'source': source, 'id': chapterId});
      if (response.statusCode == 200 && response.data['status'] == true) {
        return List<String>.from(response.data['data']);
      } else {
        throw Exception('Gagal load gambar');
      }
    } catch (e) {
      rethrow;
    }
  }

  // --- 4. NOTIFIKASI ---
  Future<void> sendNotification({required String title, required String cover, required String userEmail, required bool isAdded, String? discordWebhook, String? telegramToken, String? telegramChatId}) async {
    if (!isAdded) return;
    try {
      await _dio.post('$baseUrl/notify', data: {
        'title': title, 'cover': cover, 'user_email': userEmail, 'status': isAdded,
        'discord_webhook': discordWebhook, 'telegram_bot_token': telegramToken, 'telegram_chat_id': telegramChatId,
      });
    } catch (e) { print("Error notif: $e"); }
  }
}