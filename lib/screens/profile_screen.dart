import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'favorite_screen.dart';
import 'notification_settings_screen.dart';
import 'history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Variabel untuk menampung pesan error spesifik
  String? _emailError;
  String? _passwordError;

  // Fungsi Validasi & Submit
  void _submit() async {
    // 1. Reset Error Dulu
    setState(() {
      _emailError = null;
      _passwordError = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 2. Validasi Lokal Sederhana
    if (email.isEmpty) {
      setState(() => _emailError = "Email tidak boleh kosong");
      setState(() => _isLoading = false);
      return;
    }
    if (password.length < 6) {
      setState(() => _passwordError = "Password minimal 6 karakter");
      setState(() => _isLoading = false);
      return;
    }

    try {
      if (_isLoginMode) {
        await _auth.signIn(email: email, password: password);
        // Login Sukses
      } else {
        await _auth.signUp(email: email, password: password);
        if (mounted) {
           _showSuccessDialog("Berhasil Daftar!", "Silakan login dengan akun barumu.");
           setState(() => _isLoginMode = true);
        }
      }
    } catch (e) {
      // 3. Tangkap Error dari Supabase & Tampilkan di Field
      final msg = e.toString().toLowerCase();
      
      setState(() {
        if (msg.contains("invalid login credentials")) {
          _passwordError = "Email atau Password salah!";
          _emailError = " "; // Kasih error kosong biar border jadi merah juga
        } else if (msg.contains("user already registered")) {
          _emailError = "Email ini sudah terdaftar.";
        } else if (msg.contains("password")) {
          _passwordError = "Format password salah.";
        } else {
          // Error lain (misal koneksi)
          _showErrorDialog("Terjadi Kesalahan", msg.replaceAll("exception:", ""));
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Dialog Cantik untuk Error Umum
  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(title, style: const TextStyle(color: Colors.redAccent)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(color: Colors.blue)),
          )
        ],
      ),
    );
  }

    // Dialog Cantik untuk Sukses
  void _showSuccessDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(title, style: const TextStyle(color: Colors.greenAccent)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(color: Colors.blue)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _auth.authStateChanges,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        // --- TAMPILAN JIKA SUDAH LOGIN (PROFIL) ---
        if (session != null) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              title: const Text("Profil Saya"),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 3),
                      color: Colors.grey[900],
                    ),
                    child: const Icon(Icons.person, size: 80, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    session.user.email ?? "User",
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text("Member Rex4Red", style: TextStyle(color: Colors.grey)),

                  const SizedBox(height: 30),
                  ListTile(
                    leading: const Icon(Icons.favorite, color: Colors.redAccent),
                    title: const Text("Koleksi Favorit Saya", style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoriteScreen()));
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.history, color: Colors.blueAccent), // Icon Jam/History
                    title: const Text("Riwayat Baca", style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.notifications, color: Colors.amber),
                    title: const Text("Atur Notifikasi", style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()));
                    },
                  ),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _auth.signOut(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[900],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("LOGOUT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          );
        }

        // --- TAMPILAN LOGIN / REGISTER (DESIGN BARU) ---
        return Scaffold(
          backgroundColor: Colors.black,
          body: SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. LOGO / HEADER
                  const Icon(Icons.menu_book_rounded, size: 80, color: Colors.blueAccent),
                  const SizedBox(height: 10),
                  const Text(
                    "Rex4Red",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _isLoginMode ? "Selamat datang kembali!" : "Bergabunglah dengan kami!",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 50),

                  // 2. INPUT EMAIL
                  _buildTextField(
                    controller: _emailController,
                    label: "Email Address",
                    icon: Icons.email_outlined,
                    errorText: _emailError,
                  ),
                  const SizedBox(height: 20),

                  // 3. INPUT PASSWORD
                  _buildTextField(
                    controller: _passwordController,
                    label: "Password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                    errorText: _passwordError,
                  ),
                  
                  const SizedBox(height: 40),

                  // 4. TOMBOL ACTION
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                      : Container(
                          height: 55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Colors.blueAccent, Colors.purpleAccent],
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              _isLoginMode ? "MASUK SEKARANG" : "DAFTAR AKUN",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                  
                  const SizedBox(height: 20),

                  // 5. SWITCH LOGIN/REGISTER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLoginMode ? "Belum punya akun?" : "Sudah punya akun?",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLoginMode = !_isLoginMode;
                            _emailError = null;
                            _passwordError = null;
                          });
                        },
                        child: Text(
                          _isLoginMode ? "Daftar" : "Login",
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // WIDGET INPUT FIELD KUSTOM (Supaya rapi)
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.grey),
            prefixIcon: Icon(icon, color: errorText != null ? Colors.redAccent : Colors.grey),
            
            // Warna Background Input
            filled: true,
            fillColor: Colors.grey[900],
            
            // Border Normal
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            
            // Border saat diklik (Fokus)
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
            
            // Border saat ERROR (Merah)
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),

            // Pesan Error Muncul di Sini (Bukan SnackBar)
            errorText: errorText, 
            
            // Tombol Intip Password
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}