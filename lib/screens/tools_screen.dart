import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:dio/dio.dart'; 
import 'detail_screen.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text("Tools Manga 🛠️", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.blueAccent,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            isScrollable: false,
            tabs: [
              Tab(icon: Icon(Icons.currency_exchange), text: "Kurs"),
              Tab(icon: Icon(Icons.access_time), text: "Jadwal"),
              Tab(icon: Icon(Icons.casino_rounded), text: "Gacha"),
            ],
          ),
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            CurrencyConverterView(),
            WorldClockView(),
            ShakeGachaView(),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 3: SHAKE TO GACHA (API REX4RED) 🎲
// ==========================================
class ShakeGachaView extends StatefulWidget {
  const ShakeGachaView({super.key});

  @override
  State<ShakeGachaView> createState() => _ShakeGachaViewState();
}

class _ShakeGachaViewState extends State<ShakeGachaView> {
  final Dio _dio = Dio();
  List<dynamic> _gachaPool = [];
  bool _isPoolReady = false;
  
  StreamSubscription? _accelerometerSubscription;
  bool _isDetecting = true;

  @override
  void initState() {
    super.initState();
    _fetchGachaPool(); 
    _startListeningSensor();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  // 🔥 FUNGSI FETCH API ASLI (KOMIKINDO) 🔥
  Future<void> _fetchGachaPool() async {
    try {
      // Menggunakan API KomikIndo milikmu (Endpoint Popular)
      final response = await _dio.get("https://rex4red-komik-api-scrape.hf.space/komik/popular");
      
      if (response.statusCode == 200) {
        // Cek struktur response. Biasanya API scraper langsung mengembalikan List atau Map
        // Asumsi: API mengembalikan List langsung atau Map dengan key 'data'
        final data = response.data;
        
        if (mounted) {
          setState(() {
            // Jika data langsung berupa List
            if (data is List) {
              _gachaPool = data;
            } 
            // Jika data dibungkus key 'data' (sesuaikan dengan output API aslimu)
            else if (data is Map && data['data'] is List) {
              _gachaPool = data['data'];
            }
            
            _isPoolReady = true;
          });
        }
      }
    } catch (e) {
      print("Gagal fetch gacha pool: $e");
      // Fallback Data jika API down (supaya tidak crash)
      if(mounted) {
        setState(() {
          _gachaPool = [
            {'title': 'One Piece', 'image': 'https://upload.wikimedia.org/wikipedia/en/9/90/One_Piece%2C_Volume_61_Cover_%28Japanese%29.jpg', 'endpoint': 'one-piece'},
            {'title': 'Jujutsu Kaisen', 'image': 'https://upload.wikimedia.org/wikipedia/en/4/46/Jujutsu_Kaisen_cover.jpg', 'endpoint': 'jujutsu-kaisen'},
          ];
          _isPoolReady = true;
        });
      }
    }
  }

  void _startListeningSensor() {
    const double shakeThreshold = 15.0; 

    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      if (!_isDetecting || !_isPoolReady || _gachaPool.isEmpty) return;

      if (event.x.abs() > shakeThreshold || event.y.abs() > shakeThreshold || event.z.abs() > shakeThreshold) {
        _triggerGacha();
      }
    });
  }

  void _triggerGacha() async {
    setState(() => _isDetecting = false);

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 500);
    }

    // Ambil Random Item
    final random = Random();
    final winner = _gachaPool[random.nextInt(_gachaPool.length)];

    if (!mounted) return;

    // Mapping Data sesuai API KomikIndo
    final String title = winner['title'] ?? "Unknown Title";
    final String cover = winner['image'] ?? winner['thumb'] ?? ""; 
    final String endpoint = winner['endpoint'] ?? ""; 
    
    // Tentukan Source secara eksplisit
    const String source = 'komikindo'; 

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("🎉 GACHA GET! 🎉", textAlign: TextAlign.center, style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Manga takdirmu hari ini adalah:", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 15),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  cover, 
                  height: 200, 
                  fit: BoxFit.cover,
                  errorBuilder: (c,e,s) => Container(height: 200, color: Colors.grey, child: const Icon(Icons.broken_image)),
                ),
              ),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _isDetecting = true);
              }, 
              child: const Text("Coba Lagi")
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _isDetecting = true);
                
                if (endpoint.isNotEmpty) {
                  // 🔥 Navigasi ke DetailScreen dengan data API KomikIndo 🔥
                  Navigator.push(context, MaterialPageRoute(builder: (context) => DetailScreen(
                    source: source,   // 'komikindo'
                    mangaId: endpoint,// Endpoint valid
                    title: title, 
                    cover: cover
                  )));
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data manga tidak valid")));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text("Baca Sekarang", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.vibration, size: 80, color: Colors.blueAccent.withOpacity(0.7)),
          const SizedBox(height: 20),
          const Text(
            "Shake Your Phone!", 
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _isPoolReady 
                  ? "Siap! Goyangkan HP-mu untuk mendapatkan rekomendasi manga!" 
                  : "Mengambil data dari Rex4Red API...",
              textAlign: TextAlign.center,
              style: TextStyle(color: _isPoolReady ? Colors.grey : Colors.amber),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 1 & 2 (TETAP SAMA - COPY BAGIAN BAWAH INI)
// ==========================================
class CurrencyConverterView extends StatefulWidget {
  const CurrencyConverterView({super.key});

  @override
  State<CurrencyConverterView> createState() => _CurrencyConverterViewState();
}

class _CurrencyConverterViewState extends State<CurrencyConverterView> {
  final TextEditingController _controller = TextEditingController();
  double _result = 0.0;
  final Map<String, double> _rates = {'IDR': 1, 'USD': 15850, 'JPY': 105, 'GBP': 20100, 'KRW': 11.5};
  String _fromCurrency = 'JPY'; String _toCurrency = 'IDR';   

  void _convert() {
    double amount = double.tryParse(_controller.text) ?? 0;
    double inIdr = amount * _rates[_fromCurrency]!;
    double finalResult = inIdr / _rates[_toCurrency]!;
    setState(() { _result = finalResult; });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHeader("Cek Harga Komik Fisik 📚", "Cek estimasi harga komik impor."),
          const SizedBox(height: 25),
          TextField(controller: _controller, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: "Masukkan Harga", labelStyle: TextStyle(color: Colors.grey[400]), prefixIcon: const Icon(Icons.attach_money, color: Colors.blueAccent), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!), borderRadius: BorderRadius.circular(12)), focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)), filled: true, fillColor: Colors.grey[900]), onChanged: (val) => _convert()),
          const SizedBox(height: 20),
          Row(children: [Expanded(child: _buildDropdown("Dari", _fromCurrency, (val) { setState(() => _fromCurrency = val!); _convert(); })), const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.arrow_forward, color: Colors.grey)), Expanded(child: _buildDropdown("Ke", _toCurrency, (val) { setState(() => _toCurrency = val!); _convert(); }))]),
          const SizedBox(height: 30),
          Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue[900]!, Colors.blue[800]!]), borderRadius: BorderRadius.circular(20)), child: Column(children: [const Text("Estimasi Harga:", style: TextStyle(color: Colors.white70)), Text(NumberFormat.currency(locale: 'id', symbol: _toCurrency == 'IDR' ? 'Rp ' : '$_toCurrency ', decimalDigits: 2).format(_result), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))])),
      ]),
    );
  }

  Widget _buildDropdown(String label, String value, Function(String?) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.grey)), const SizedBox(height: 5), Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[800]!)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, dropdownColor: Colors.grey[900], isExpanded: true, style: const TextStyle(color: Colors.white, fontSize: 16), items: _rates.keys.map((String key) => DropdownMenuItem<String>(value: key, child: Text(key))).toList(), onChanged: onChanged)) )]);
  }
  Widget _buildHeader(String title, String subtitle) { return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13))]); }
}

class WorldClockView extends StatefulWidget {
  const WorldClockView({super.key});
  @override
  State<WorldClockView> createState() => _WorldClockViewState();
}

class _WorldClockViewState extends State<WorldClockView> {
  late Timer _timer;
  DateTime _now = DateTime.now().toUtc();
  bool _isLocaleInitialized = false; 

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) { if (mounted) setState(() { _isLocaleInitialized = true; }); });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) { if (mounted) setState(() { _now = DateTime.now().toUtc(); }); });
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!_isLocaleInitialized) return const Center(child: CircularProgressIndicator());
    return ListView(padding: const EdgeInsets.all(20), children: [
      _buildHeader("Jadwal Rilis Global 🌍", "Pantau waktu server."),
      const SizedBox(height: 20),
      _buildClockCard("WIB", "Lokal", _now.add(const Duration(hours: 7)), Colors.blue),
      _buildClockCard("WITA", "Lokal", _now.add(const Duration(hours: 8)), Colors.cyan),
      _buildClockCard("WIT", "Lokal", _now.add(const Duration(hours: 9)), Colors.teal),
      const Divider(color: Colors.grey, height: 30),
      _buildClockCard("Tokyo (JST)", "Manga 🇯🇵", _now.add(const Duration(hours: 9)), Colors.redAccent),
      _buildClockCard("Seoul (KST)", "Manhwa 🇰🇷", _now.add(const Duration(hours: 9)), Colors.pinkAccent),
      _buildClockCard("London (GMT)", "Global 🇬🇧", _now.add(const Duration(hours: 0)), Colors.purpleAccent),
    ]);
  }

  Widget _buildClockCard(String city, String tag, DateTime time, Color color) {
    return Container(margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.3))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(city, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), Text(tag, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)), Text(DateFormat('EEEE, d MMM yyyy', 'id_ID').format(time), style: TextStyle(color: Colors.grey[500], fontSize: 12))]), Text(DateFormat('HH:mm:ss').format(time), style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'monospace'))]));
  }
  Widget _buildHeader(String title, String subtitle) { return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13))]); }
}