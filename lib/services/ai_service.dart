import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static const String _apiKey = "AIzaSyDL1as5SkQBHF2WEvXyv3hr6m8P3g6909M";
  static const String _baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";

  static final Map<String, List<String>> _cache = {};

  static String _cleanText(String text) {
    return text
        .replaceAll("```json", "")
        .replaceAll("```", "")
        .trim();
  }

  static bool _isSimpleQuery(String prompt) {
    final p = prompt.toLowerCase().trim();

    return p.split(" ").length <= 3 &&
        !p.contains("mc") &&
        !p.contains("overpower") &&
        !p.contains("dark") &&
        !p.contains("revenge") &&
        !p.contains("tanpa") &&
        !p.contains("mirip") &&
        !p.contains("isekai");
  }

  // 🔵 MODE 1: REKOMENDASI (LIST)
  static Future<List<String>> generateTitles(String prompt) async {
    final key = prompt.toLowerCase().trim();

    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    if (_isSimpleQuery(prompt)) {
      return [prompt];
    }

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl?key=$_apiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "Return ONLY valid JSON array of 3-5 manga titles.\n"
                      "NO explanation.\n"
                      "NO markdown.\n\n"
                      "User request:\n$prompt",
                }
              ]
            }
          ],
        }),
      );

      final data = jsonDecode(response.body);

      final rawText =
          data['candidates'][0]['content']['parts'][0]['text'];

      final cleanedText = _cleanText(rawText);

      final List<dynamic> decoded = jsonDecode(cleanedText);

      final result = decoded.map((e) => e.toString()).toList();

      _cache[key] = result;

      return result;
    } catch (e) {
      return [prompt];
    }
  }

  // 🟢 MODE 2: CHATBOT
  static Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl?key=$_apiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": """
              Kamu adalah AI chatbot di aplikasi manga.

              Aturan:
              - Kalau user minta rekomendasi → kasih 3-5 manga
              - Setiap manga WAJIB ada:
                • Judul
                • Alasan singkat
                • Genre/Tag

              - Kalau user minta SINOPSIS:
                → boleh jawab lebih panjang (3-6 kalimat)
                → jelaskan alur cerita tanpa spoiler besar

              - Kalau ngobrol biasa:
                → balas santai, natural, tidak terlalu pendek

              - Gunakan bahasa yang enak dibaca dan rapi

              User: $message
              """
                }
              ]
            }
          ],
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }

      final data = jsonDecode(response.body);

      final text =
          data['candidates'][0]['content']['parts'][0]['text'];

      return _cleanText(text);
    } catch (e) {
      return "Lagi error, coba lagi.";
    }
  }
}   