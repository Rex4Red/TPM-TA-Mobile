import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

/// Layer Neural Network: y = activation(x * W + b)
class _DenseLayer {
  final int rows;
  final int cols;
  final Float32List weights;
  final Float32List biases;

  _DenseLayer({
    required this.rows,
    required this.cols,
    required this.weights,
    required this.biases,
  });

  /// Forward pass: input (1 x rows) → output (1 x cols)
  Float32List forward(Float32List input, {required bool useSigmoid}) {
    final output = Float32List(cols);

    for (int j = 0; j < cols; j++) {
      double sum = biases[j];
      for (int i = 0; i < rows; i++) {
        sum += input[i] * weights[i * cols + j];
      }
      // Activation: ReLU untuk hidden layers, Sigmoid untuk output layer
      if (useSigmoid) {
        output[j] = 1.0 / (1.0 + exp(-sum)); // sigmoid
      } else {
        output[j] = sum > 0 ? sum : 0; // relu
      }
    }

    return output;
  }
}

/// Service untuk sistem rekomendasi manga berbasis Neural Network.
///
/// Menggunakan model weights yang sudah dilatih (pure Dart inference,
/// tanpa dependency TFLite) untuk memprediksi manga yang cocok
/// berdasarkan preferensi genre user.
class RecommendationService {
  static const String _prefBoxName = 'session';

  List<_DenseLayer> _layers = [];
  List<String> _genreList = [];
  List<Map<String, dynamic>> _mangaList = [];
  bool _isLoaded = false;

  // ==========================================
  // INISIALISASI MODEL
  // ==========================================

  /// Load model weights + metadata (genre_list, manga_list)
  Future<void> loadModel() async {
    if (_isLoaded) return;

    try {
      // 1. Load daftar genre
      final genreJson = await rootBundle.loadString('assets/genre_list.json');
      _genreList = List<String>.from(json.decode(genreJson));

      // 2. Load daftar manga
      final mangaJson = await rootBundle.loadString('assets/manga_list.json');
      _mangaList = List<Map<String, dynamic>>.from(
        (json.decode(mangaJson) as List)
            .map((e) => Map<String, dynamic>.from(e)),
      );

      // 3. Load model weights (binary format)
      final weightData = await rootBundle.load('assets/manga_weights.bin');
      _layers = _parseWeights(weightData);

      _isLoaded = true;
      print('RecommendationService: Model loaded '
          '(${_genreList.length} genres, ${_mangaList.length} manga, ${_layers.length} layers)');
    } catch (e) {
      print('RecommendationService: Failed to load model: $e');
      _isLoaded = false;
    }
  }

  /// Parse binary weights file ke list of DenseLayer
  List<_DenseLayer> _parseWeights(ByteData data) {
    final layers = <_DenseLayer>[];
    int offset = 0;

    // Header: jumlah layer
    final numLayers = data.getInt32(offset, Endian.little);
    offset += 4;

    for (int l = 0; l < numLayers; l++) {
      // Shape
      final rows = data.getInt32(offset, Endian.little);
      offset += 4;
      final cols = data.getInt32(offset, Endian.little);
      offset += 4;

      // Weights (rows x cols floats)
      final weights = Float32List(rows * cols);
      for (int i = 0; i < rows * cols; i++) {
        weights[i] = data.getFloat32(offset, Endian.little);
        offset += 4;
      }

      // Biases (cols floats)
      final biases = Float32List(cols);
      for (int i = 0; i < cols; i++) {
        biases[i] = data.getFloat32(offset, Endian.little);
        offset += 4;
      }

      layers.add(_DenseLayer(
        rows: rows,
        cols: cols,
        weights: weights,
        biases: biases,
      ));
    }

    return layers;
  }

  /// Apakah model sudah siap dipakai
  bool get isReady => _isLoaded;

  /// Daftar semua genre yang tersedia
  List<String> get availableGenres => List.unmodifiable(_genreList);

  /// Jumlah manga dalam database
  int get mangaCount => _mangaList.length;

  // ==========================================
  // SIMPAN/AMBIL PREFERENSI GENRE USER
  // ==========================================

  /// Simpan genre pilihan user ke Hive
  Future<void> saveUserGenres(List<String> genres) async {
    final box = Hive.box(_prefBoxName);
    final email = box.get('currentEmail');
    if (email == null) return;

    await box.put('preferred_genres_$email', genres);
  }

  /// Ambil genre pilihan user dari Hive
  List<String> getUserGenres() {
    final box = Hive.box(_prefBoxName);
    final email = box.get('currentEmail');
    if (email == null) return [];

    final stored = box.get('preferred_genres_$email');
    if (stored == null) return [];
    return List<String>.from(stored);
  }

  /// Cek apakah user sudah memilih genre
  bool hasUserSelectedGenres() {
    return getUserGenres().isNotEmpty;
  }

  // ==========================================
  // PREDIKSI REKOMENDASI (Pure Dart)
  // ==========================================

  /// Dapatkan rekomendasi manga berdasarkan genre yang dipilih user.
  ///
  /// [selectedGenres] - List genre pilihan user
  /// [topN] - Jumlah rekomendasi (default: 10)
  List<Map<String, dynamic>> getRecommendations({
    List<String>? selectedGenres,
    int topN = 10,
  }) {
    if (!_isLoaded || _layers.isEmpty) return [];

    final genres = selectedGenres ?? getUserGenres();
    if (genres.isEmpty) return [];

    // 1. Buat input vektor (one-hot encoding)
    var current = Float32List(_genreList.length);
    for (final genre in genres) {
      final idx = _genreList.indexOf(genre);
      if (idx >= 0) current[idx] = 1.0;
    }

    // 2. Forward pass through all layers
    for (int i = 0; i < _layers.length; i++) {
      final isLastLayer = (i == _layers.length - 1);
      current = _layers[i].forward(current, useSigmoid: isLastLayer);
    }

    // 3. current sekarang berisi skor per manga (0.0 - 1.0)
    final scores = current;

    // 4. Urutkan berdasarkan skor tertinggi
    final indexed = List.generate(
      _mangaList.length,
      (i) => MapEntry(i, i < scores.length ? scores[i] : 0.0),
    );
    indexed.sort((a, b) => b.value.compareTo(a.value));

    // 5. Ambil top-N
    final results = <Map<String, dynamic>>[];
    for (var i = 0; i < topN && i < indexed.length; i++) {
      final mangaIdx = indexed[i].key;
      final score = indexed[i].value;
      final manga = _mangaList[mangaIdx];

      results.add({
        'title': manga['title'] ?? '',
        'manga_id': manga['manga_id'] ?? '',
        'source': manga['source'] ?? 'shinigami',
        'genres': List<String>.from(manga['genres'] ?? []),
        'cover_url': manga['cover_url'] ?? '',
        'rating': manga['rating'] ?? '',
        'score': score,
      });
    }

    return results;
  }

  /// Tidak perlu dispose — pure Dart, no native resources
  void dispose() {
    _layers = [];
    _isLoaded = false;
  }
}
