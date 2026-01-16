import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <--- Import ini
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase
  await Supabase.initialize(
    // 👇 COPY DARI .ENV NEXT.JS KAMU
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
      // ... (ThemeData biarkan sama) ...
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}