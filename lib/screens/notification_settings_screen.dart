import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final _discordController = TextEditingController();
  final _telegramTokenController = TextEditingController();
  final _telegramChatIdController = TextEditingController();
  
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Ambil data settingan dari Supabase
  void _loadSettings() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _supabase
          .from('user_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (data != null) {
        setState(() {
          _discordController.text = data['discord_webhook'] ?? '';
          _telegramTokenController.text = data['telegram_bot_token'] ?? '';
          _telegramChatIdController.text = data['telegram_chat_id'] ?? '';
        });
      }
    } catch (e) {
      print("Error loading settings: $e");
    }
  }

  // Simpan data ke Supabase
  void _saveSettings() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Upsert: Update jika ada, Insert jika belum ada
      await _supabase.from('user_settings').upsert({
        'user_id': user.id,
        'discord_webhook': _discordController.text.trim(),
        'telegram_bot_token': _telegramTokenController.text.trim(),
        'telegram_chat_id': _telegramChatIdController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pengaturan Disimpan! ✅"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal Simpan: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Atur Notifikasi")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Discord Webhook", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _buildTextField(_discordController, "Contoh: https://discord.com/api/webhooks/..."),
            
            const SizedBox(height: 24),
            
            const Text("Telegram Bot (Opsional)", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _buildTextField(_telegramTokenController, "Bot Token (Dapat dari BotFather)"),
            const SizedBox(height: 8),
            _buildTextField(_telegramChatIdController, "Chat ID Anda (Angka)"),

            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("SIMPAN PENGATURAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}