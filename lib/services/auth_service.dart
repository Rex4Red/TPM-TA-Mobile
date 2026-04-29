import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static const String _usersBoxName = 'users';
  static const String _sessionBoxName = 'session';

  final SupabaseClient _supabase = Supabase.instance.client;

  // ==========================================
  // HIVE INITIALIZATION
  // ==========================================

  /// Buka Hive box (dipanggil di main.dart)
  static Future<void> initHive() async {
    await Hive.openBox(_usersBoxName);
    await Hive.openBox(_sessionBoxName);
  }

  // ==========================================
  // PASSWORD HASHING (SHA-256)
  // ==========================================

  /// Hash password menggunakan SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ==========================================
  // REGISTER (HIVE + SUPABASE SILENT)
  // ==========================================

  Future<void> signUp({required String email, required String password}) async {
    final usersBox = Hive.box(_usersBoxName);

    // 1. Cek apakah email sudah terdaftar di Hive
    if (usersBox.containsKey(email.toLowerCase())) {
      throw Exception('Email sudah terdaftar');
    }

    // 2. Hash password & simpan ke Hive
    final hashedPassword = _hashPassword(password);
    await usersBox.put(email.toLowerCase(), {
      'email': email.toLowerCase(),
      'password': hashedPassword,
      'createdAt': DateTime.now().toIso8601String(),
    });

    // 3. Silent register ke Supabase (background, biar bookmark/history tetap jalan)
    try {
      await _supabase.auth.signUp(email: email, password: password);
    } catch (e) {
      print('⚠️ Supabase signUp silent failed (OK): $e');
      // Tidak throw error — Hive sudah berhasil, itu yang penting
    }
  }

  // ==========================================
  // LOGIN (HIVE FIRST + SUPABASE SILENT)
  // ==========================================

  Future<void> signIn({required String email, required String password}) async {
    final usersBox = Hive.box(_usersBoxName);
    final sessionBox = Hive.box(_sessionBoxName);

    // 1. Cek email di Hive
    final userData = usersBox.get(email.toLowerCase());
    if (userData == null) {
      throw Exception('Invalid login credentials');
    }

    // 2. Cek password (hash comparison)
    final hashedInput = _hashPassword(password);
    if (userData['password'] != hashedInput) {
      throw Exception('Invalid login credentials');
    }

    // 3. ✅ Login Hive berhasil → simpan session lokal
    await sessionBox.put('isLoggedIn', true);
    await sessionBox.put('currentEmail', email.toLowerCase());

    // 4. Silent login ke Supabase (biar bookmark/history tetap jalan)
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      print('⚠️ Supabase signIn silent failed (OK): $e');
      // Tidak throw error — User sudah tervalidasi via Hive
    }
  }

  // ==========================================
  // LOGOUT
  // ==========================================

  Future<void> signOut() async {
    final sessionBox = Hive.box(_sessionBoxName);

    // 1. Hapus session lokal
    await sessionBox.put('isLoggedIn', false);
    await sessionBox.delete('currentEmail');

    // 2. Silent logout Supabase
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('⚠️ Supabase signOut silent failed (OK): $e');
    }
  }

  // ==========================================
  // SESSION CHECK (DARI HIVE)
  // ==========================================

  /// Cek apakah user sedang login (dari Hive)
  bool get isLoggedIn {
    final sessionBox = Hive.box(_sessionBoxName);
    return sessionBox.get('isLoggedIn', defaultValue: false) == true;
  }

  /// Ambil email user yang sedang login (dari Hive)
  String? get currentEmail {
    final sessionBox = Hive.box(_sessionBoxName);
    return sessionBox.get('currentEmail');
  }

  // ==========================================
  // PROFILE PHOTO (HIVE LOKAL)
  // ==========================================

  /// Ambil path foto profil user
  String? get profilePhotoPath {
    final sessionBox = Hive.box(_sessionBoxName);
    final email = currentEmail;
    if (email == null) return null;
    return sessionBox.get('profilePhoto_$email');
  }

  /// Simpan path foto profil ke Hive
  Future<void> setProfilePhoto(String path) async {
    final sessionBox = Hive.box(_sessionBoxName);
    final email = currentEmail;
    if (email == null) return;
    await sessionBox.put('profilePhoto_$email', path);
  }

  /// Hapus foto profil
  Future<void> removeProfilePhoto() async {
    final sessionBox = Hive.box(_sessionBoxName);
    final email = currentEmail;
    if (email == null) return;
    await sessionBox.delete('profilePhoto_$email');
  }

  /// Kompatibilitas: return User Supabase jika ada (untuk service lain)
  User? get currentUser => _supabase.auth.currentUser;

  /// Stream auth state dari Supabase (untuk kompatibilitas)
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // ==========================================
  // SILENT SUPABASE RE-LOGIN (untuk splash)
  // ==========================================

  /// Re-login ke Supabase di background saat app start
  /// Dipanggil di splash_screen jika Hive session aktif
  Future<void> silentSupabaseLogin() async {
    final sessionBox = Hive.box(_sessionBoxName);
    final usersBox = Hive.box(_usersBoxName);

    final email = sessionBox.get('currentEmail');
    if (email == null) return;

    final userData = usersBox.get(email);
    if (userData == null) return;

    // Kita tidak bisa recover plaintext password dari hash
    // Tapi Supabase session mungkin masih aktif dari login sebelumnya
    // Jika session expired, bookmark/history akan gagal tapi login tetap lokal
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        print('⚠️ Supabase session expired - fitur cloud mungkin terbatas');
      }
    } catch (e) {
      print('⚠️ Supabase re-login check failed: $e');
    }
  }
}