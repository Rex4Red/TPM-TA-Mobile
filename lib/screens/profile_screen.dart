import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import 'favorite_screen.dart';
import 'notification_settings_screen.dart';
import 'history_screen.dart';
import 'main_screen.dart';
import 'genre_selection_screen.dart';

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
      backgroundColor: ProfileScreenColors.sheetBg,
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
                decoration: BoxDecoration(color: ProfileScreenColors.sheetHandle, borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 15),
              const Text("Foto Profil", style: TextStyle(color: ProfileScreenColors.sheetTitle, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: ProfileScreenColors.cameraIcon),
                title: const Text("Ambil dari Kamera", style: TextStyle(color: ProfileScreenColors.sheetTitle)),
                onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: ProfileScreenColors.galleryIcon),
                title: const Text("Pilih dari Galeri", style: TextStyle(color: ProfileScreenColors.sheetTitle)),
                onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); },
              ),
              if (_auth.profilePhotoPath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: ProfileScreenColors.deleteIcon),
                  title: const Text("Hapus Foto", style: TextStyle(color: ProfileScreenColors.deleteIcon)),
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
          SnackBar(content: Text("Gagal memilih foto: $e"), backgroundColor: ProfileScreenColors.snackbarError),
        );
      }
    }
  }

  // 📝 Tampilkan bottom sheet Saran & Kesan
  void _showSaranKesanSheet() {
    final kesanCtrl = TextEditingController(text: _auth.kesan);
    final saranCtrl = TextEditingController(text: _auth.saran);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ProfileScreenColors.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: ProfileScreenColors.sheetHandle, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 15),
              const Center(
                child: Text(
                  "📝 Saran & Kesan",
                  style: TextStyle(color: ProfileScreenColors.sheetTitle, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 5),
              Center(
                child: Text(
                  "Mata Kuliah Teknologi Pemrograman Mobile",
                  style: TextStyle(color: ProfileScreenColors.sheetSubtitle, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 25),

              // KESAN
              const Text("Kesan", style: TextStyle(color: ProfileScreenColors.saranLabel, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: kesanCtrl,
                maxLines: 4,
                style: const TextStyle(color: ProfileScreenColors.inputText),
                decoration: InputDecoration(
                  hintText: "Tuliskan kesan kamu selama mengikuti mata kuliah ini...",
                  hintStyle: TextStyle(color: ProfileScreenColors.inputHint),
                  filled: true,
                  fillColor: ProfileScreenColors.inputFill,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: ProfileScreenColors.inputBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: ProfileScreenColors.saranLabel),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // SARAN
              const Text("Saran", style: TextStyle(color: ProfileScreenColors.saranLabel, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: saranCtrl,
                maxLines: 4,
                style: const TextStyle(color: ProfileScreenColors.inputText),
                decoration: InputDecoration(
                  hintText: "Tuliskan saran kamu untuk mata kuliah ini...",
                  hintStyle: TextStyle(color: ProfileScreenColors.inputHint),
                  filled: true,
                  fillColor: ProfileScreenColors.inputFill,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: ProfileScreenColors.inputBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: ProfileScreenColors.saranLabel),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // TOMBOL SIMPAN
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _auth.saveSaranKesan(
                      kesan: kesanCtrl.text.trim(),
                      saran: saranCtrl.text.trim(),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("✅ Saran & Kesan berhasil disimpan!"),
                          backgroundColor: ProfileScreenColors.saranSnackbar,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save, color: ProfileScreenColors.saranBtnText),
                  label: const Text("Simpan", style: TextStyle(color: ProfileScreenColors.saranBtnText, fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProfileScreenColors.saranBtnBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
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
        // Auto-login setelah register berhasil
        await _auth.signIn(email: email, password: password);
        // Redirect ke Genre Selection (pilih genre untuk rekomendasi AI)
        if (mounted) {
          setState(() => _isNavigating = true);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const GenreSelectionScreen()),
            (route) => false,
          );
          return;
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
        backgroundColor: ProfileScreenColors.dialogBg,
        title: Text(title, style: const TextStyle(color: ProfileScreenColors.errorDialogTitle)),
        content: Text(content, style: const TextStyle(color: ProfileScreenColors.dialogContent)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(color: ProfileScreenColors.dialogBtn)),
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
        backgroundColor: ProfileScreenColors.dialogBg,
        title: Text(title, style: const TextStyle(color: ProfileScreenColors.successDialogTitle)),
        content: Text(content, style: const TextStyle(color: ProfileScreenColors.dialogContent)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(color: ProfileScreenColors.dialogBtn)),
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
      return const Scaffold(backgroundColor: ProfileScreenColors.background);
    }

    // --- TAMPILAN JIKA SUDAH LOGIN (PROFIL) ---
    if (isLoggedIn) {
      final userEmail = _auth.currentEmail ?? 'User';
      return Scaffold(
        backgroundColor: ProfileScreenColors.background,
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
                        border: Border.all(color: ProfileScreenColors.avatarBorder, width: 3),
                        color: ProfileScreenColors.avatarBg,
                        image: _auth.profilePhotoPath != null
                            ? DecorationImage(
                                image: FileImage(File(_auth.profilePhotoPath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _auth.profilePhotoPath == null
                          ? const Icon(Icons.person, size: 60, color: ProfileScreenColors.avatarIcon)
                          : null,
                    ),
                    // Badge kamera
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: ProfileScreenColors.cameraBadgeBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: ProfileScreenColors.background, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: ProfileScreenColors.cameraBadgeIcon),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                userEmail,
                style: const TextStyle(
                  color: ProfileScreenColors.profileName,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Member MangaMotion",
                style: TextStyle(color: ProfileScreenColors.profileSubtitle),
              ),

              const SizedBox(height: 30),
              ListTile(
                leading: const Icon(Icons.favorite, color: ProfileScreenColors.menuFavorite),
                title: const Text("Koleksi Favorit Saya", style: TextStyle(color: ProfileScreenColors.menuText)),
                trailing: const Icon(Icons.arrow_forward_ios, color: ProfileScreenColors.menuArrow, size: 16),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoriteScreen()));
                },
              ),

              ListTile(
                leading: const Icon(Icons.history, color: ProfileScreenColors.menuHistory),
                title: const Text("Riwayat Baca", style: TextStyle(color: ProfileScreenColors.menuText)),
                trailing: const Icon(Icons.arrow_forward_ios, color: ProfileScreenColors.menuArrow, size: 16),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
                },
              ),

              ListTile(
                leading: const Icon(Icons.notifications, color: ProfileScreenColors.menuNotif),
                title: const Text("Atur Notifikasi", style: TextStyle(color: ProfileScreenColors.menuText)),
                trailing: const Icon(Icons.arrow_forward_ios, color: ProfileScreenColors.menuArrow, size: 16),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()));
                },
              ),

              // 🔒 TOGGLE BIOMETRIC LOCK
              if (_isBiometricAvailable)
                SwitchListTile(
                  secondary: Icon(
                    Icons.fingerprint,
                    color: _isBiometricEnabled ? ProfileScreenColors.bioOn : ProfileScreenColors.bioOff,
                  ),
                  title: const Text("Kunci Biometrik", style: TextStyle(color: ProfileScreenColors.menuText)),
                  subtitle: Text(
                    _isBiometricEnabled
                        ? "Sidik jari aktif saat membuka app"
                        : "Gunakan sidik jari untuk membuka aplikasi",
                    style: const TextStyle(color: ProfileScreenColors.profileSubtitle, fontSize: 12),
                  ),
                  value: _isBiometricEnabled,
                  activeThumbColor: ProfileScreenColors.bioOn,
                  onChanged: (bool value) async {
                    if (value) {
                      final authenticated = await _biometricService.authenticate();
                      if (authenticated) {
                        await _biometricService.setBiometricEnabled(true);
                        setState(() => _isBiometricEnabled = true);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("🔒 Kunci biometrik diaktifkan!"), backgroundColor: ProfileScreenColors.bioSnackbarOn),
                          );
                        }
                      }
                    } else {
                      await _biometricService.setBiometricEnabled(false);
                      setState(() => _isBiometricEnabled = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("🔓 Kunci biometrik dinonaktifkan."), backgroundColor: ProfileScreenColors.bioSnackbarOff),
                        );
                      }
                    }
                  },
                ),

              // 📝 SARAN & KESAN
              ListTile(
                leading: const Icon(Icons.rate_review, color: ProfileScreenColors.menuSaran),
                title: const Text("Saran & Kesan", style: TextStyle(color: ProfileScreenColors.menuText)),
                subtitle: Text(
                  _auth.kesan.isNotEmpty ? "Sudah diisi ✅" : "Belum diisi",
                  style: TextStyle(color: _auth.kesan.isNotEmpty ? ProfileScreenColors.menuSaran : ProfileScreenColors.menuArrow, fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: ProfileScreenColors.menuArrow, size: 16),
                onTap: _showSaranKesanSheet,
              ),

              const Divider(color: ProfileScreenColors.menuArrow),
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
                    backgroundColor: ProfileScreenColors.logoutBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text(
                    "LOGOUT",
                    style: TextStyle(color: ProfileScreenColors.logoutText, fontWeight: FontWeight.bold),
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
      backgroundColor: ProfileScreenColors.background,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. LOGO / HEADER
              const Icon(Icons.menu_book_rounded, size: 80, color: ProfileScreenColors.loginLogo),
              const SizedBox(height: 10),
              const Text(
                "MangaMotion",
                textAlign: TextAlign.center,
                style: TextStyle(color: ProfileScreenColors.loginTitle, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 5),
              Text(
                _isLoginMode ? "Selamat datang kembali!" : "Bergabunglah dengan kami!",
                textAlign: TextAlign.center,
                style: const TextStyle(color: ProfileScreenColors.loginSubtitle),
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
                  ? const Center(child: CircularProgressIndicator(color: ProfileScreenColors.loginSpinner))
                  : Container(
                      height: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(colors: [ProfileScreenColors.gradientStart, ProfileScreenColors.gradientEnd]),
                        boxShadow: [
                          BoxShadow(color: ProfileScreenColors.loginBtnShadow, blurRadius: 10, offset: const Offset(0, 5)),
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
                          style: const TextStyle(color: ProfileScreenColors.loginBtnText, fontWeight: FontWeight.bold, fontSize: 16),
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
                    style: const TextStyle(color: ProfileScreenColors.loginSubtitle),
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
                      style: const TextStyle(color: ProfileScreenColors.loginLink, fontWeight: FontWeight.bold),
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
          style: const TextStyle(color: ProfileScreenColors.inputText),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: ProfileScreenColors.fieldLabel),
            prefixIcon: Icon(icon, color: errorText != null ? ProfileScreenColors.fieldError : ProfileScreenColors.fieldLabel),
            filled: true,
            fillColor: ProfileScreenColors.fieldFill,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ProfileScreenColors.fieldBorderNormal),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ProfileScreenColors.fieldBorderFocused),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ProfileScreenColors.fieldError),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ProfileScreenColors.fieldError, width: 2),
            ),
            errorText: errorText,
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: ProfileScreenColors.fieldLabel,
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

// ==================== COLOR SETTINGS ====================
class ProfileScreenColors {
  // --- UMUM ---
  static const background          = Colors.black;            // Background utama
  static const inputText           = Colors.white;            // Teks input field
  static final inputHint           = Colors.grey[600];        // Hint teks di field
  static final inputFill           = Colors.grey[850];        // Fill background input saran
  static final inputBorder         = Colors.grey[700]!;       // Border input saran

  // --- BOTTOM SHEET (Foto & Saran) ---
  static final sheetBg             = Colors.grey[900];        // Background bottom sheet
  static final sheetHandle         = Colors.grey[700];        // Handle bar atas sheet
  static const sheetTitle          = Colors.white;            // Judul sheet
  static final sheetSubtitle       = Colors.grey[400];        // Sub-judul sheet

  // --- OPSI FOTO ---
  static const cameraIcon          = Colors.blueAccent;       // Ikon kamera
  static const galleryIcon         = Colors.greenAccent;      // Ikon galeri
  static const deleteIcon          = Colors.redAccent;        // Ikon & teks hapus foto
  static const snackbarError       = Colors.red;              // Snackbar error foto

  // --- SARAN & KESAN ---
  static const saranLabel          = Colors.tealAccent;       // Label "Kesan" & "Saran"
  static const saranSnackbar       = Colors.teal;             // Snackbar simpan sukses
  static const saranBtnText        = Colors.white;            // Teks tombol simpan
  static final saranBtnBg          = Colors.teal[700];        // Background tombol simpan

  // --- DIALOG ---
  static final dialogBg            = Colors.grey[900];        // Background dialog
  static const dialogContent       = Colors.white70;          // Konten dialog
  static const dialogBtn           = Colors.blue;             // Tombol OK dialog
  static const errorDialogTitle    = Colors.redAccent;        // Judul error dialog
  static const successDialogTitle  = Colors.greenAccent;      // Judul sukses dialog

  // --- PROFIL (SUDAH LOGIN) ---
  static const avatarBorder        = Colors.blue;             // Border lingkaran avatar
  static final avatarBg            = Colors.grey[900];        // Background avatar kosong
  static const avatarIcon          = Colors.white;            // Ikon person avatar
  static const cameraBadgeBg       = Colors.blueAccent;       // Badge kamera di avatar
  static const cameraBadgeIcon     = Colors.white;            // Ikon badge kamera
  static const profileName         = Colors.white;            // Nama user (email)
  static const profileSubtitle     = Colors.grey;             // "Member MangaMotion"

  // --- MENU LIST ---
  static const menuText            = Colors.white;            // Teks menu item
  static const menuArrow           = Colors.grey;             // Arrow & divider
  static const menuFavorite        = Colors.redAccent;        // Ikon favorit
  static const menuHistory         = Colors.blueAccent;       // Ikon riwayat
  static const menuNotif           = Colors.amber;            // Ikon notifikasi
  static const menuSaran           = Colors.tealAccent;       // Ikon saran & kesan

  // --- BIOMETRIK ---
  static const bioOn               = Colors.greenAccent;      // Ikon & thumb biometrik aktif
  static const bioOff              = Colors.grey;             // Ikon biometrik mati
  static const bioSnackbarOn       = Colors.green;            // Snackbar bio aktif
  static const bioSnackbarOff      = Colors.grey;             // Snackbar bio mati

  // --- LOGOUT ---
  static final logoutBg            = Colors.red[900];         // Background tombol logout
  static const logoutText          = Colors.white;            // Teks logout

  // --- LOGIN / REGISTER ---
  static const loginLogo           = Colors.blueAccent;       // Logo ikon buku
  static const loginTitle          = Colors.white;            // "MangaMotion"
  static const loginSubtitle       = Colors.grey;             // Sub-judul & teks switch
  static const loginSpinner        = Colors.blueAccent;       // Loading spinner login
  static const gradientStart       = Colors.blueAccent;       // Gradient tombol (kiri)
  static const gradientEnd         = Colors.purpleAccent;     // Gradient tombol (kanan)
  static final loginBtnShadow      = Colors.blue.withOpacity(0.3); // Shadow tombol
  static const loginBtnText        = Colors.white;            // Teks tombol login
  static const loginLink           = Colors.blueAccent;       // Link "Daftar"/"Login"

  // --- TEXT FIELD LOGIN ---
  static const fieldLabel          = Colors.grey;             // Label & suffix icon
  static final fieldFill           = Colors.grey[900];        // Fill background field
  static final fieldBorderNormal   = Colors.grey[800]!;       // Border normal
  static const fieldBorderFocused  = Colors.blueAccent;       // Border fokus
  static const fieldError          = Colors.redAccent;        // Border error
}