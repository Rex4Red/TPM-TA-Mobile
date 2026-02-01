import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart'; // ✅ Import Splash Screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://htgfkfatiqcqifhmjhso.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh0Z2ZrZmF0aXFjcWlmaG1qaHNvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc3NjMyNjQsImV4cCI6MjA4MzMzOTI2NH0.SL02F09ktvYxId4IWluy7ZIM7duxXsc8IB2hAQZulaE', 
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rex4Red Manga',
      
      // Tema Gelap yang Konsisten
      theme: ThemeData(
        brightness: Brightness.dark, // Set mode gelap global
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black, // Background Hitam
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
          surface: Colors.black, // Warna surface (card/sheet) hitam
        ),
      ),
      
      // 🔥 APLIKASI DIMULAI DARI SPLASH SCREEN 🔥
      // Splash screen nanti akan mengecek login & mengarahkan ke MainScreen/ProfileScreen
      home: const SplashScreen(),
    );
  }
}