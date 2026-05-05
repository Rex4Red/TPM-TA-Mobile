import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _notifEnabled = true;
  bool _isLoading = true;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final enabled = await NotificationService().isEnabled();
    if (mounted) {
      setState(() {
        _notifEnabled = enabled;
        _isLoading = false;
      });
    }
  }

  void _toggleNotification(bool value) async {
    setState(() => _notifEnabled = value);
    await NotificationService().setEnabled(value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? "Notifikasi Diaktifkan 🔔" : "Notifikasi Dimatikan 🔕"),
          backgroundColor: value ? NotifSettingsColors.snackbarOn : NotifSettingsColors.snackbarOff,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // Kirim notif test (bookmark style)
  void _sendTestNotification() {
    NotificationService().showBookmarkNotification(
      mangaTitle: "Solo Leveling (Test Notifikasi)",
      isAdded: true,
    );
  }

  // 🔍 Cek chapter baru sekarang juga
  void _checkNow() async {
    setState(() => _isChecking = true);

    final found = await NotificationService().checkNow();

    if (mounted) {
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(found > 0
              ? "🎉 Ditemukan $found chapter baru!"
              : "✅ Semua manga sudah up-to-date!"),
          backgroundColor: found > 0 ? NotifSettingsColors.snackbarFound : NotifSettingsColors.snackbarUpToDate,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NotifSettingsColors.background,
      appBar: AppBar(
        title: const Text("Pengaturan Notifikasi"),
        backgroundColor: NotifSettingsColors.appBarBg,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Toggle Utama
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: NotifSettingsColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: NotifSettingsColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _notifEnabled ? Icons.notifications_active : Icons.notifications_off,
                          color: _notifEnabled ? NotifSettingsColors.iconOn : NotifSettingsColors.iconOff,
                          size: 40,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Push Notification",
                                style: TextStyle(color: NotifSettingsColors.titleText, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _notifEnabled
                                    ? "Cek chapter baru setiap 5 menit"
                                    : "Notifikasi dimatikan",
                                style: TextStyle(color: NotifSettingsColors.subtitleText, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _notifEnabled,
                          onChanged: _toggleNotification,
                          activeThumbColor: NotifSettingsColors.switchThumb,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info Jenis Notifikasi
                  const Text(
                    "Jenis Notifikasi",
                    style: TextStyle(color: NotifSettingsColors.sectionTitle, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  _buildNotifItem(
                    Icons.favorite,
                    "Bookmark Update",
                    "Notifikasi saat manga ditambah/dihapus dari favorit",
                    NotifSettingsColors.bookmarkIcon,
                  ),
                  _buildNotifItem(
                    Icons.menu_book,
                    "Chapter Baru (Otomatis)",
                    "Cek setiap 5 menit — notifikasi jika ada chapter baru di manga favorit",
                    NotifSettingsColors.chapterIcon,
                  ),
                  _buildNotifItem(
                    Icons.timer,
                    "Interval Pengecekan",
                    "Setiap 5 menit selama aplikasi terbuka",
                    NotifSettingsColors.intervalIcon,
                  ),

                  const Spacer(),

                  // Tombol Cek Sekarang
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: (_notifEnabled && !_isChecking) ? _checkNow : null,
                      icon: _isChecking
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(color: NotifSettingsColors.checkBtnText, strokeWidth: 2),
                            )
                          : Icon(Icons.search, color: NotifSettingsColors.checkBtnText),
                      label: Text(
                        _isChecking ? "MENGECEK..." : "CEK CHAPTER BARU SEKARANG",
                        style: TextStyle(color: NotifSettingsColors.checkBtnText, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NotifSettingsColors.checkBtnBg,
                        disabledBackgroundColor: NotifSettingsColors.checkBtnDisabled,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Tombol Test Notif
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _notifEnabled ? _sendTestNotification : null,
                      icon: const Icon(Icons.notifications),
                      label: const Text("KIRIM TEST NOTIFIKASI"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: NotifSettingsColors.testBtnColor,
                        side: BorderSide(color: _notifEnabled ? NotifSettingsColors.testBtnColor : NotifSettingsColors.iconOff),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildNotifItem(IconData icon, String title, String desc, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NotifSettingsColors.cardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: NotifSettingsColors.titleText, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(color: NotifSettingsColors.itemDesc, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotifSettingsColors {
  static const background        = Colors.black;         // Background halaman
  static final appBarBg          = Colors.grey[900];     // Background AppBar
  static final cardBg            = Colors.grey[900];     // Background card toggle & item
  static final cardBorder        = Colors.blue.withOpacity(0.3); // Border card utama
  static const iconOn            = Colors.amber;         // Ikon notif aktif (lonceng)
  static const iconOff           = Colors.grey;          // Ikon notif mati
  static const titleText         = Colors.white;         // Judul teks (Push Notification, item)
  static final subtitleText      = Colors.grey[400];     // Sub-judul toggle
  static const switchThumb       = Colors.blue;          // Thumb switch aktif
  static const sectionTitle      = Colors.blue;          // Judul "Jenis Notifikasi"
  static const bookmarkIcon      = Colors.redAccent;     // Ikon bookmark item
  static const chapterIcon       = Colors.green;         // Ikon chapter baru item
  static const intervalIcon      = Colors.amber;         // Ikon interval item
  static final itemDesc          = Colors.grey[500];     // Deskripsi item notif
  static const checkBtnBg        = Colors.green;         // Background tombol "Cek Sekarang"
  static const checkBtnText      = Colors.white;         // Teks & ikon tombol cek
  static final checkBtnDisabled  = Colors.grey[800];     // Tombol cek saat disabled
  static const testBtnColor      = Colors.blue;          // Warna tombol test notif
  static const snackbarOn        = Colors.green;         // Snackbar notif aktif
  static final snackbarOff       = Colors.grey[800];     // Snackbar notif mati
  static const snackbarFound     = Colors.green;         // Snackbar chapter ditemukan
  static const snackbarUpToDate  = Colors.blue;          // Snackbar sudah up-to-date
}