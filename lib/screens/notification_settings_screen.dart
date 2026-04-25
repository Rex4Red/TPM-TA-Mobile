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
          backgroundColor: value ? Colors.green : Colors.grey[800],
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
          backgroundColor: found > 0 ? Colors.green : Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Pengaturan Notifikasi"),
        backgroundColor: Colors.grey[900],
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
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _notifEnabled ? Icons.notifications_active : Icons.notifications_off,
                          color: _notifEnabled ? Colors.amber : Colors.grey,
                          size: 40,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Push Notification",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _notifEnabled
                                    ? "Cek chapter baru setiap 5 menit"
                                    : "Notifikasi dimatikan",
                                style: TextStyle(color: Colors.grey[400], fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _notifEnabled,
                          onChanged: _toggleNotification,
                          activeThumbColor: Colors.blue,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info Jenis Notifikasi
                  const Text(
                    "Jenis Notifikasi",
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  _buildNotifItem(
                    Icons.favorite,
                    "Bookmark Update",
                    "Notifikasi saat manga ditambah/dihapus dari favorit",
                    Colors.redAccent,
                  ),
                  _buildNotifItem(
                    Icons.menu_book,
                    "Chapter Baru (Otomatis)",
                    "Cek setiap 5 menit — notifikasi jika ada chapter baru di manga favorit",
                    Colors.green,
                  ),
                  _buildNotifItem(
                    Icons.timer,
                    "Interval Pengecekan",
                    "Setiap 5 menit selama aplikasi terbuka",
                    Colors.amber,
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
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.search, color: Colors.white),
                      label: Text(
                        _isChecking ? "MENGECEK..." : "CEK CHAPTER BARU SEKARANG",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        disabledBackgroundColor: Colors.grey[800],
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
                        foregroundColor: Colors.blue,
                        side: BorderSide(color: _notifEnabled ? Colors.blue : Colors.grey),
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
        color: Colors.grey[900],
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
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}