import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Cek apakah user sedang login
  User? get currentUser => _supabase.auth.currentUser;

  // Stream untuk memantau status login (Realtime)
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Fungsi Login
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw Exception(e.toString()); // Lempar error biar ditangkap UI
    }
  }

  // Fungsi Register
  Future<void> signUp({required String email, required String password}) async {
    try {
      await _supabase.auth.signUp(email: email, password: password);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Fungsi Logout
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}