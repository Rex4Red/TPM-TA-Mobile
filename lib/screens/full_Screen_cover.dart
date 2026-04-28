import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FullScreenCover extends StatefulWidget {
  final String imageUrl;
  final String source;

  const FullScreenCover({
    super.key,
    required this.imageUrl,
    required this.source,
  });

  @override
  State<FullScreenCover> createState() => _FullScreenCoverState();
}

class _FullScreenCoverState extends State<FullScreenCover> {
  // Variabel untuk menyimpan posisi rotasi (dalam radian)
  double _rotationY = 0;
  double _rotationX = 0;

  // StreamSubscription wajib disimpan agar bisa dibatalkan (dispose)
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    // Memulai mendengarkan data dari sensor Giroskop
    _gyroSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        // y: rotasi kiri-kanan (roll)
        // x: rotasi depan-belakang (pitch)
        // 0.03 adalah angka sensitivitas, silakan sesuaikan
        _rotationY += event.y * 0.05;
        _rotationX += event.x * 0.05;

        // Batasi (clamp) rotasi agar tidak berputar 360 derajat
        // 0.5 radian itu sekitar 28 derajat miring
        _rotationY = _rotationY.clamp(-1.0, 1.0);
        _rotationX = _rotationX.clamp(-1.0, 1.0);
      });
    });
  }

  @override
  void dispose() {
    // SANGAT PENTING: Batalkan subscription sensor agar tidak memory leak
    _gyroSubscription?.cancel();
    super.dispose();
  }

  // Helper untuk header (sama seperti di DetailScreen)
  Map<String, String> _getHeaders(String source) {
    String referer = source == 'shinigami' 
        ? "https://shinigami.id/" 
        : "https://komikindo.tv/";
    return {
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
      "Referer": referer
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Efek Visual Utama
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context), // Klik gambar untuk balik
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // Memberikan efek perspektif 3D
                  ..rotateX(-_rotationX)  // Miring depan/belakang
                  ..rotateY(_rotationY),   // Miring kiri/kanan
                child: Hero(
                  tag: 'manga_cover_hero', // Tag harus sama dengan di DetailScreen
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          // Bayangan dinamis mengikuti kemiringan
                          color: Colors.blueAccent.withOpacity(0.2),
                          blurRadius: 30,
                          offset: Offset(_rotationY * 50, _rotationX * 50),
                        ),
                      ],
                    ),
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      httpHeaders: _getHeaders(widget.source),
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Tombol Tutup (Aksesibilitas)
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          // Indikator Sensor (Opsional - Bagus untuk demo tugas)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Miringkan HP untuk melihat detail",
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}