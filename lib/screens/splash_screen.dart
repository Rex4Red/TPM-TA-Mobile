import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:math';
import 'main_screen.dart'; // Ganti dengan halaman utama kamu
import 'profile_screen.dart'; // Ganti jika halaman login ada di sini

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  // Variabel untuk efek Glitch
  double _glitchOffsetX = 0.0;
  double _glitchOffsetY = 0.0;
  Color _glitchColor = Colors.transparent;
  Timer? _glitchTimer;

  @override
  void initState() {
    super.initState();

    // 1. Setup Controller Animasi Utama (Durasi 3 Detik)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // 2. Animasi Scale (Membesar sedikit: Zoom In)
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo),
    );

    // 3. Animasi Opacity (Fade In)
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    // 4. Jalankan Animasi
    _controller.forward();
    _startGlitchEffect();

    // 5. Cek Login & Navigasi setelah animasi selesai
    _checkAuthAndNavigate();
  }

  // --- LOGIKA GLITCH EFFECT ---
  void _startGlitchEffect() {
    // Timer ini akan mengacak posisi gambar setiap 50 milidetik
    // Memberikan efek "Rusak" atau "Cyberpunk"
    _glitchTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_controller.value > 0.7) {
        // Hentikan glitch saat animasi sudah 70% (Stabilize)
        setState(() {
          _glitchOffsetX = 0;
          _glitchOffsetY = 0;
          _glitchColor = Colors.transparent;
        });
        timer.cancel();
      } else {
        setState(() {
          // Random getaran kecil
          _glitchOffsetX = (Random().nextDouble() * 10) - 5; 
          _glitchOffsetY = (Random().nextDouble() * 10) - 5;
          
          // Kadang-kadang muncul warna merah/biru (Chromatic Aberration)
          if (Random().nextBool()) {
            _glitchColor = Colors.red.withOpacity(0.5);
          } else {
            _glitchColor = Colors.blue.withOpacity(0.5);
          }
        });
      }
    });
  }

  // --- LOGIKA NAVIGASI ---
  void _checkAuthAndNavigate() async {
    // Tunggu durasi animasi (3 detik) + sedikit buffer
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    
    // Navigasi (Hapus halaman splash dari history stack)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        // Jika sudah login ke MainScreen (Home), jika belum ke ProfileScreen (Login)
        // Sesuaikan 'MainScreen' dengan nama class halaman utamamu (misal HomeScreen)
        builder: (context) => session != null ? const MainScreen() : const ProfileScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _glitchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Layer 1: Bayangan Glitch (Warna-warni)
                    if (_controller.value < 0.7)
                      Transform.translate(
                        offset: Offset(-_glitchOffsetX, -_glitchOffsetY),
                        child: Image.asset(
                          'assets/images/logo_r.png',
                          width: 200,
                          color: _glitchColor,
                          colorBlendMode: BlendMode.srcATop,
                        ),
                      ),
                    
                    // Layer 2: Gambar Utama (Sedikit bergetar)
                    Transform.translate(
                      offset: Offset(_glitchOffsetX, _glitchOffsetY),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // LOGO
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(_controller.value * 0.5),
                                  blurRadius: 50,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo_r.png',
                              width: 200,
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // TEXT "Rex4Red" (Muncul belakangan)
                          if (_controller.value > 0.3)
                            Text(
                              "Rex4Red",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 5 * _controller.value, // Huruf melebar saat animasi
                                shadows: [
                                  Shadow(
                                    blurRadius: 10,
                                    color: Colors.redAccent.withOpacity(0.8),
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// NOTE: Buat Dummy MainScreen kalau belum ada, biar tidak error importnya.
