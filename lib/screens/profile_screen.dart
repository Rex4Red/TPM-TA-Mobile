import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import 'favorite_screen.dart';
import 'notification_settings_screen.dart';
import 'history_screen.dart';
import 'main_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  final BiometricService _biometricService = BiometricService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isNavigating = false;

  // 🔒 Biometric
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;

  // Variabel untuk menampung pesan error spesifik
  String? _emailError;
  String? _passwordError;

  // 📸 Image Picker
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
  }

  // 📸 Pilih foto profil
  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 15),
              const Text("Foto Profil", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blueAccent),
                title: const Text("Ambil dari Kamera", style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.greenAccent),
                title: const Text("Pilih dari Galeri", style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); },
              ),
              if (_auth.profilePhotoPath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                  title: const Text("Hapus Foto", style: TextStyle(color: Colors.redAccent)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _auth.removeProfilePhoto();
                    if (mounted) setState(() {});
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (image != null) {
        await _auth.setProfilePhoto(image.path);
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memilih foto: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 🔒 Load status biometric saat init
  void _loadBiometricStatus() async {
    final available = await _biometricService.isBiometricAvailable();
    final enabled = await _biometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _isBiometricAvailable = available;
        _isBiometricEnabled = enabled;
      });
    }
  }

  // Fungsi Validasi & Submit (HIVE-BASED)
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
        // 🔥 LOGIN via Hive (+ Supabase silent di background)
        await _auth.signIn(email: email, password: password);
        // Login Sukses → langsung ke Home
        if (mounted) {
          setState(() => _isNavigating = true);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
          return;
        }
      } else {
        // 🔥 REGISTER via Hive (+ Supabase silent di background)
        await _auth.signUp(email: email, password: password);
        if (mounted) {
          _showSuccessDialog(
            "Berhasil Daftar!",
            "Silakan login dengan akun barumu.",
          );
          setState(() => _isLoginMode = true);
        }
      }
    } catch (e) {
      // 3. Tangkap Error & Tampilkan di Field
      final msg = e.toString().toLowerCase();

      setState(() {
        if (msg.contains("invalid login credentials")) {
          _passwordError = "Email atau Password salah!";
          _emailError = " "; // Kasih error kosong biar border jadi merah juga
        } else if (msg.contains("sudah terdaftar") || msg.contains("already registered")) {
          _emailError = "Email ini sudah terdaftar.";
        } else if (msg.contains("password")) {
          _passwordError = "Format password salah.";
        } else {
          // Error lain (misal koneksi)
          _showErrorDialog(
            "Terjadi Kesalahan",
            msg.replaceAll("exception:", ""),
          );
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
          ),
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
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 📦 Cek login dari Hive (bukan Supabase StreamBuilder)
    final isLoggedIn = _auth.isLoggedIn;

    // --- Jika sedang navigasi ke Home, tampilkan layar hitam ---
    if (_isNavigating) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    // --- TAMPILAN JIKA SUDAH LOGIN (PROFIL) ---
    if (isLoggedIn) {
      final userEmail = _auth.currentEmail ?? 'User';
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
              // 📸 FOTO PROFIL (TAP UNTUK GANTI)
              GestureDetector(
                onTap: _showImageOptions,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue, width: 3),
                        color: Colors.grey[900],
                        image: _auth.profilePhotoPath != null
                            ? DecorationImage(
                                image: FileImage(File(_auth.profilePhotoPath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _auth.profilePhotoPath == null
                          ? const Icon(Icons.person, size: 60, color: Colors.white)
                          : null,
                    ),
                    // Badge kamera
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                userEmail,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Member Rex4Red",
                style: TextStyle(color: Colors.grey),
              ),

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
                leading: const Icon(Icons.history, color: Colors.blueAccent),
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

              // 🔒 TOGGLE BIOMETRIC LOCK
              if (_isBiometricAvailable)
                SwitchListTile(
                  secondary: Icon(
                    Icons.fingerprint,
                    color: _isBiometricEnabled ? Colors.greenAccent : Colors.grey,
                  ),
                  title: const Text("Kunci Biometrik", style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    _isBiometricEnabled
                        ? "Sidik jari aktif saat membuka app"
                        : "Gunakan sidik jari untuk membuka aplikasi",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  value: _isBiometricEnabled,
                  activeThumbColor: Colors.greenAccent,
                  onChanged: (bool value) async {
                    if (value) {
                      final authenticated = await _biometricService.authenticate();
                      if (authenticated) {
                        await _biometricService.setBiometricEnabled(true);
                        setState(() => _isBiometricEnabled = true);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("🔒 Kunci biometrik diaktifkan!"), backgroundColor: Colors.green),
                          );
                        }
                      }
                    } else {
                      await _biometricService.setBiometricEnabled(false);
                      setState(() => _isBiometricEnabled = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("🔓 Kunci biometrik dinonaktifkan."), backgroundColor: Colors.grey),
                        );
                      }
                    }
                  },
                ),

              const Divider(color: Colors.grey),
              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    await _auth.signOut();
                    if (mounted) setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text(
                    "LOGOUT",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // --- TAMPILAN LOGIN / REGISTER ---
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
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
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
                        gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent]),
                        boxShadow: [
                          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
            filled: true,
            fillColor: Colors.grey[900],
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
            errorText: errorText,
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
