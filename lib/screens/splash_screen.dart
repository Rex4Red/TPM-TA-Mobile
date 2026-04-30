import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_screen.dart';
import 'profile_screen.dart';
import '../services/biometric_service.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _time = 0;
  Timer? _timer;

  final BiometricService _biometricService = BiometricService();
  final AuthService _authService = AuthService();
  bool _showRetryButton = false;
  String _biometricStatus = '';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _startMotion();
    _checkAuthAndNavigate();
  }

  void _startMotion() {
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      setState(() {
        _time += 0.016;
      });
    });
  }

  // --- 🔒 LOGIKA NAVIGASI + BIOMETRIC (CEK DARI HIVE) ---
  void _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    // 📦 Cek session dari HIVE (local database)
    final isLoggedIn = _authService.isLoggedIn;

    if (isLoggedIn) {
      // Silent re-login ke Supabase (biar bookmark/history tetap jalan)
      await _authService.silentSupabaseLogin();

      // User sudah login, cek apakah biometric diaktifkan
      final biometricEnabled = await _biometricService.isBiometricEnabled();

      if (biometricEnabled) {
        await _performBiometricAuth();
      } else {
        _navigateTo(const MainScreen());
      }
    } else {
      _navigateTo(const ProfileScreen());
    }
  }

  Future<void> _performBiometricAuth() async {
    if (!mounted) return;

    setState(() {
      _biometricStatus = 'Verifikasi sidik jari...';
      _showRetryButton = false;
    });

    final isAuthenticated = await _biometricService.authenticate();

    if (!mounted) return;

    if (isAuthenticated) {
      _navigateTo(const MainScreen());
    } else {
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
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 MOTION CALCULATION
    final floatX = sin(_time * 2) * 6;
    final floatY = cos(_time * 2) * 6;

    final glowPulse = (sin(_time * 2) + 1) / 2;

    final slightTilt = sin(_time) * 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _controller.value,
              child: Transform.scale(
                scale: 0.9 + (_controller.value * 0.2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔥 LOGO AREA
                    Transform.translate(
                      offset: Offset(floatX, floatY),
                      child: Transform.rotate(
                        angle: slightTilt,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow belakang
                            Container(
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.blueAccent.withOpacity(0.25 * glowPulse),
                                    Colors.purpleAccent.withOpacity(0.2 * glowPulse),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),

                            // Shadow dynamic
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.4 * glowPulse),
                                    blurRadius: 40,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                            ),

                            // LOGO UTAMA
                            Image.asset(
                              'assets/images/logo_mangaMotion.png', // 🔥 GANTI KE LOGO KAMU
                              width: 200,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // TEXT
                    Text(
                      "MangaMotion",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2 + (sin(_time * 2) * 1),
                      ),
                    ),

                    // 🔒 BIOMETRIC STATUS
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

                    // 🔒 RETRY BUTTON
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
            );
          },
        ),
      ),
    );
  }
}