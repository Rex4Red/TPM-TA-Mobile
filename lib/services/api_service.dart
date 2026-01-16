import 'package:dio/dio.dart';
import '../models/manga_model.dart';
import '../models/manga_detail_model.dart'; // Jangan lupa import ini!

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
          if (query.isNotEmpty) 'q': query,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        final List data = response.data['data'];
        // Convert list JSON menjadi list Object Manga
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
        // Ambil data dari key 'data' dan masukkan ke cetakan MangaDetail
        return MangaDetail.fromJson(response.data['data']);
      } else {
        throw Exception('Gagal load data detail');
      }
    } catch (e) {
      print("❌ Error Fetching Detail: $e");
      rethrow;
    }
  }

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
        // API mengembalikan array string URL gambar
        return List<String>.from(response.data['data']);
      } else {
        throw Exception('Gagal load gambar chapter');
      }
    } catch (e) {
      print("❌ Error Fetching Images: $e");
      rethrow;
    }
  }
}