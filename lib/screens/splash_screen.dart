import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:math';
import 'main_screen.dart';
import 'profile_screen.dart';
import '../services/biometric_service.dart';

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

  // 🔒 Biometric
  final BiometricService _biometricService = BiometricService();
  bool _showRetryButton = false;
  String _biometricStatus = '';

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
    _glitchTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_controller.value > 0.7) {
        setState(() {
          _glitchOffsetX = 0;
          _glitchOffsetY = 0;
          _glitchColor = Colors.transparent;
        });
        timer.cancel();
      } else {
        setState(() {
          _glitchOffsetX = (Random().nextDouble() * 10) - 5; 
          _glitchOffsetY = (Random().nextDouble() * 10) - 5;
          if (Random().nextBool()) {
            _glitchColor = Colors.red.withOpacity(0.5);
          } else {
            _glitchColor = Colors.blue.withOpacity(0.5);
          }
        });
      }
    });
  }

  // --- 🔒 LOGIKA NAVIGASI + BIOMETRIC ---
  void _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // User sudah login, cek apakah biometric diaktifkan
      final biometricEnabled = await _biometricService.isBiometricEnabled();

      if (biometricEnabled) {
        // 🔒 Biometric diaktifkan → minta verifikasi
        await _performBiometricAuth();
      } else {
        // Biometric tidak aktif → langsung masuk
        _navigateTo(const MainScreen());
      }
    } else {
      // Belum login → ke halaman login
      _navigateTo(const ProfileScreen());
    }
  }

  // 🔒 Proses autentikasi biometric
  Future<void> _performBiometricAuth() async {
    if (!mounted) return;

    setState(() {
      _biometricStatus = 'Verifikasi sidik jari...';
      _showRetryButton = false;
    });

    final isAuthenticated = await _biometricService.authenticate();

    if (!mounted) return;

    if (isAuthenticated) {
      // ✅ Berhasil → masuk ke MainScreen
      _navigateTo(const MainScreen());
    } else {
      // ❌ Gagal → tampilkan tombol retry
      setState(() {
        _biometricStatus = 'Verifikasi gagal. Coba lagi.';
        _showRetryButton = true;
      });
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => screen),
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
                                letterSpacing: 5 * _controller.value,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10,
                                    color: Colors.redAccent.withOpacity(0.8),
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),

                          // 🔒 STATUS BIOMETRIC
                          if (_biometricStatus.isNotEmpty) ...[
                            const SizedBox(height: 30),
                            Icon(
                              Icons.fingerprint,
                              size: 48,
                              color: _showRetryButton ? Colors.redAccent : Colors.blueAccent,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _biometricStatus,
                              style: TextStyle(
                                color: _showRetryButton ? Colors.redAccent : Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],

                          // 🔒 TOMBOL RETRY BIOMETRIC
                          if (_showRetryButton) ...[
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _performBiometricAuth,
                              icon: const Icon(Icons.fingerprint, size: 20),
                              label: const Text("Coba Lagi"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ],
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
