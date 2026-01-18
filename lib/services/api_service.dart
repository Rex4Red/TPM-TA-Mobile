import 'package:dio/dio.dart';
import '../models/manga_model.dart';
import '../models/manga_detail_model.dart'; 

class ApiService {
  // URL Vercel (Production)
  static const String baseUrl = 'https://project-web-manga-rex4red.vercel.app/api/mobile';

  final Dio _dio = Dio();

  // --- 1. AMBIL LIST MANGA (HOME) ---
  Future<List<Manga>> fetchMangaList({String source = 'shinigami', String query = ''}) async {
    try {
      final response = await _dio.get(
        '$baseUrl/list',
        queryParameters: {
          'source': source,
          'q': query.isNotEmpty ? query : null, // Kirim null jika kosong biar rapi
        },
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

  // --- 2. AMBIL DETAIL MANGA (DETAIL SCREEN) ---
  Future<MangaDetail> fetchMangaDetail({required String source, required String id}) async {
    try {
      final response = await _dio.get(
        '$baseUrl/detail',
        queryParameters: {
          'source': source,
          'id': id,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        return MangaDetail.fromJson(response.data['data']);
      } else {
        throw Exception('Gagal load data detail');
      }
    } catch (e) {
      print("❌ Error Fetching Detail: $e");
      rethrow;
    }
  }

  // --- 3. AMBIL GAMBAR CHAPTER (BACA KOMIK) ---
  Future<List<String>> fetchChapterImages({required String source, required String chapterId}) async {
    try {
      final response = await _dio.get(
        '$baseUrl/chapter',
        queryParameters: {
          'source': source,
          'id': chapterId,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        return List<String>.from(response.data['data']);
      } else {
        throw Exception('Gagal load gambar chapter');
      }
    } catch (e) {
      print("❌ Error Fetching Images: $e");
      rethrow;
    }
  }

  // --- 4. KIRIM NOTIFIKASI (DISCORD / TELEGRAM) ---
  // Fungsi ini dipanggil saat user menekan tombol Love di DetailScreen
  Future<void> sendNotification({
    required String title,
    required String cover,
    required String userEmail,
    required bool isAdded, // True = Ditambah, False = Dihapus
    // Parameter Opsional (Diambil dari settingan user)
    String? discordWebhook,
    String? telegramToken,
    String? telegramChatId,
  }) async {
    // Kalau dihapus (unlove), tidak perlu kirim notif
    if (!isAdded) return;

    try {
      // Endpoint: /api/mobile/notify
      await _dio.post(
        '$baseUrl/notify', 
        data: {
          'title': title,
          'cover': cover,
          'user_email': userEmail,
          'status': isAdded,
          // Data settingan user (boleh null)
          'discord_webhook': discordWebhook,
          'telegram_bot_token': telegramToken,
          'telegram_chat_id': telegramChatId,
        },
      );
      print("🔔 Request Notifikasi Terkirim ke Backend!");
    } catch (e) {
      // Kita print error saja, jangan throw exception agar aplikasi tidak crash
      // karena ini hanya fitur tambahan (background process).
      print("❌ Gagal kirim notifikasi: $e");
    }
  }
}