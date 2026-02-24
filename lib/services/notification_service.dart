import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static const String _notifEnabledKey = 'notification_enabled';
  bool _isInitialized = false;

  // ========== INIT ==========
  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
    _isInitialized = true;
  }

  // 🔔 Request notification permission (Android 13+ / API 33+)
  Future<void> requestPermission() async {
    await init();
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      print('🔔 [NotifService] Permission granted: $granted');
    }
  }

  // ========== SETTINGS ==========
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notifEnabledKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifEnabledKey, value);
    
    if (value) {
      startRealtimeListener();
    } else {
      stopRealtimeListener();
    }
  }

  // ========== BOOKMARK NOTIFICATION (INSTANT) ==========
  Future<void> showBookmarkNotification({
    required String mangaTitle,
    required bool isAdded,
  }) async {
    final enabled = await isEnabled();
    if (!enabled) return;
    await init();

    final String title = isAdded ? 'Ditambahkan ke Favorit ❤️' : 'Dihapus dari Favorit 💔';

    const androidDetails = AndroidNotificationDetails(
      'bookmark_channel',
      'Bookmark Updates',
      channelDescription: 'Notifikasi saat manga ditambahkan/dihapus dari favorit',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      autoCancel: true,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      mangaTitle,
      const NotificationDetails(android: androidDetails),
    );
  }

  // ========== NEW CHAPTER NOTIFICATION ==========
  Future<void> _showNewChapterNotification({
    required String mangaTitle,
    required String newChapter,
    required String cover,
  }) async {
    await init();

    final androidDetails = AndroidNotificationDetails(
      'chapter_channel',
      'Chapter Updates',
      channelDescription: 'Notifikasi chapter baru dari manga favorit',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      styleInformation: BigTextStyleInformation(
        'Chapter terbaru: $newChapter',
        contentTitle: '📖 $mangaTitle',
        summaryText: 'Update Baru',
      ),
      autoCancel: true,
    );

    await _plugin.show(
      mangaTitle.hashCode,
      '📖 Chapter Baru!',
      '$mangaTitle — $newChapter',
      NotificationDetails(android: androidDetails),
    );
  }

  // ========== REALTIME LISTENER ==========
  void startRealtimeListener() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // 🔔 Request permission saat UI sudah siap (Android 13+)
    await requestPermission();

    print('🔔 [NotifService] Memulai Realtime Listener untuk chapter_updates...');

    // 1. Fetch notif yang terlewat (saat app ditutup)
    await _fetchMissedUpdates(user.id);

    // 2. Subscribe ke Realtime
    Supabase.instance.client
        .channel('public:chapter_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chapter_updates',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) async {
            final data = payload.newRecord;
            print('🆕 [NotifService] Realtime Update Diterima: ${data['manga_title']} → ${data['new_chapter']}');

            final enabled = await isEnabled();
            if (!enabled) return;

            // Munculkan notifikasi
            await _showNewChapterNotification(
              mangaTitle: data['manga_title'] ?? 'Unknown',
              newChapter: data['new_chapter'] ?? '',
              cover: data['cover'] ?? '',
            );

            // Tandai sudah dibaca
            await Supabase.instance.client
                .from('chapter_updates')
                .update({'is_read': true})
                .eq('id', data['id']);
          },
        )
        .subscribe();
  }

  void stopRealtimeListener() {
    Supabase.instance.client.removeAllChannels();
    print('🔕 [NotifService] Realtime Listener dihentikan.');
  }

  // ========== FETCH MISSED UPDATES ==========
  Future<void> _fetchMissedUpdates(String userId) async {
    try {
      final enabled = await isEnabled();
      if (!enabled) return;

      final missedUpdates = await Supabase.instance.client
          .from('chapter_updates')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false);

      if (missedUpdates.isEmpty) return;
      print('📥 [NotifService] Menemukan ${missedUpdates.length} update yang terlewat.');

      for (final data in missedUpdates) {
        await _showNewChapterNotification(
          mangaTitle: data['manga_title'] ?? 'Unknown',
          newChapter: data['new_chapter'] ?? '',
          cover: data['cover'] ?? '',
        );

        // Tandai sudah dibaca
        await Supabase.instance.client
            .from('chapter_updates')
            .update({'is_read': true})
            .eq('id', data['id']);
        
        // Kasih jeda sedikit antar notif supaya tidak spam sekaligus crash
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      print('❌ [fetchMissedUpdates] Error: $e');
    }
  }

  // ========== MANUAL CHECK (Langsung cek API dari Flutter) ==========
  static const String _shinigamiUrl = 'https://rex4red-shinigami-api.hf.space';
  static const String _serverUrl = 'https://rex4red-rex4red-komik-api-scrape.hf.space/api/mobile';
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  Future<int> checkNow() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('❌ [checkNow] User belum login');
        return 0;
      }

      print('🚀 [checkNow] Mulai cek chapter langsung dari API...');

      // 1. Ambil SEMUA bookmark user (semua source)
      final bookmarks = await Supabase.instance.client
          .from('bookmarks')
          .select()
          .eq('user_id', user.id);

      if (bookmarks.isEmpty) {
        print('📭 [checkNow] Tidak ada bookmark.');
        return 0;
      }

      print('📚 [checkNow] Ditemukan ${bookmarks.length} bookmark. Mengecek...');
      int newChaptersFound = 0;

      // 2. Cek setiap bookmark
      for (final bookmark in bookmarks) {
        final mangaId = bookmark['manga_id'] as String? ?? '';
        final savedChapter = bookmark['last_chapter'] as String? ?? '';
        final title = bookmark['title'] as String? ?? 'Unknown';
        final source = bookmark['source'] as String? ?? 'shinigami';

        if (mangaId.isEmpty || savedChapter.isEmpty) continue;

        try {
          print('🔍 [checkNow] Cek: "$title" (source=$source, mangaId=$mangaId, saved=$savedChapter)');
          String? latestChapter;

          if (source == 'shinigami') {
            // ====== SHINIGAMI API ======
            latestChapter = await _checkShinigami(mangaId);
          } else {
            // ====== KOMIKINDO API (via HuggingFace server) ======
            latestChapter = await _checkKomikindo(mangaId, source);
          }

          if (latestChapter != null && latestChapter != savedChapter) {
            print('🆕 [checkNow] Chapter baru: $title → $latestChapter (sebelumnya: $savedChapter)');
            newChaptersFound++;

            // 1. Insert ke chapter_updates (log/riwayat) — PERTAMA
            try {
              await Supabase.instance.client
                  .from('chapter_updates')
                  .insert({
                    'user_id': user.id,
                    'manga_id': mangaId,
                    'manga_title': title,
                    'cover': bookmark['cover'] ?? '',
                    'old_chapter': savedChapter,
                    'new_chapter': latestChapter,
                  });
              print('✅ [checkNow] Berhasil insert ke chapter_updates: $title');
            } catch (insertErr) {
              print('⚠️ [checkNow] Gagal insert chapter_updates: $insertErr');
            }

            // 2. Update bookmark dengan chapter terbaru — KEDUA
            try {
              await Supabase.instance.client
                  .from('bookmarks')
                  .update({'last_chapter': latestChapter})
                  .eq('id', bookmark['id']);
              print('✅ [checkNow] Berhasil update bookmark: $title → $latestChapter');
            } catch (updateErr) {
              print('⚠️ [checkNow] Gagal update bookmark: $updateErr');
            }

            // 3. Tampilkan notifikasi TERAKHIR (supaya DB sudah aman)
            try {
              await _showNewChapterNotification(
                mangaTitle: title,
                newChapter: latestChapter,
                cover: bookmark['cover'] ?? '',
              );
              print('✅ [checkNow] Notifikasi ditampilkan untuk: $title');
            } catch (notifErr) {
              print('⚠️ [checkNow] Gagal tampilkan notif: $notifErr');
            }

            await Future.delayed(const Duration(milliseconds: 300));
          }
        } catch (e) {
          print('⚠️ [checkNow] Error cek manga $title ($source): $e');
        }
      }

      print('✅ [checkNow] Selesai. Ditemukan $newChaptersFound chapter baru.');
      return newChaptersFound;
    } catch (e) {
      print('❌ [checkNow] Error: $e');
    }
    return 0;
  }

  // Cek chapter terbaru dari Shinigami API
  Future<String?> _checkShinigami(String mangaId) async {
    String cleanId = mangaId.replaceFirst('manga-', '');
    var response = await _dio.get('$_shinigamiUrl/komik/detail/$cleanId');
    var resData = response.data;

    if (resData['retcode'] != 0) {
      response = await _dio.get('$_shinigamiUrl/komik/detail/manga-$mangaId');
      resData = response.data;
    }

    if (resData['retcode'] == 0 && resData['data'] != null && resData['data']['latest_chapter_number'] != null) {
      return 'Ch. ${resData['data']['latest_chapter_number']}';
    }
    return null;
  }

  // Cek chapter terbaru dari Komikindo API (via HuggingFace server)
  Future<String?> _checkKomikindo(String mangaId, String source) async {
    // Bersihkan manga_id: hapus /komik/ prefix dan trailing slash
    String cleanId = mangaId;
    if (cleanId.startsWith('/komik/')) cleanId = cleanId.replaceFirst('/komik/', '');
    if (cleanId.startsWith('/')) cleanId = cleanId.substring(1);
    if (cleanId.endsWith('/')) cleanId = cleanId.substring(0, cleanId.length - 1);

    print('🌐 [Komikindo] API call: $_serverUrl/komik/detail?source=$source&id=$cleanId');

    final response = await _dio.get(
      '$_serverUrl/komik/detail',
      queryParameters: {'source': source, 'id': cleanId},
    );

    print('📦 [Komikindo] Response status: ${response.statusCode}, data_status: ${response.data['status']}');

    if (response.statusCode == 200 && response.data['status'] == true && response.data['data'] != null) {
      final data = response.data['data'];

      // Cari list chapter
      List<dynamic>? chapters;
      if (data['chapters'] is List) chapters = data['chapters'];
      else if (data['chapter_list'] is List) chapters = data['chapter_list'];
      else if (data['list_chapter'] is List) chapters = data['list_chapter'];

      if (chapters != null && chapters.isNotEmpty) {
        // Chapter pertama biasanya yang terbaru
        final latestCh = chapters.first;
        final latestTitle = latestCh['title']?.toString() ?? latestCh['name']?.toString();
        print('📖 [Komikindo] Latest chapter: $latestTitle');
        return latestTitle;
      } else {
        print('⚠️ [Komikindo] No chapters found in response');
      }
    }
    return null;
  }
}

