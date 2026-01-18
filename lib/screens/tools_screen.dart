import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // <--- PENTING: Import ini

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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
            tabs: [
              Tab(text: "Estimasi Harga", icon: Icon(Icons.currency_exchange)),
              Tab(text: "Jadwal Global", icon: Icon(Icons.access_time)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CurrencyConverterView(), 
            WorldClockView(),        
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 1: KONVERSI MATA UANG
// ==========================================
class CurrencyConverterView extends StatefulWidget {
  const CurrencyConverterView({super.key});

  @override
  State<CurrencyConverterView> createState() => _CurrencyConverterViewState();
}

class _CurrencyConverterViewState extends State<CurrencyConverterView> {
  final TextEditingController _controller = TextEditingController();
  double _result = 0.0;
  
  final Map<String, double> _rates = {
    'IDR': 1,
    'USD': 15850, 
    'JPY': 105,   
    'GBP': 20100, 
    'KRW': 11.5,  
  };

  String _fromCurrency = 'JPY'; 
  String _toCurrency = 'IDR';   

  void _convert() {
    double amount = double.tryParse(_controller.text) ?? 0;
    double inIdr = amount * _rates[_fromCurrency]!;
    double finalResult = inIdr / _rates[_toCurrency]!;

    setState(() {
      _result = finalResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader("Cek Harga Komik Fisik 📚", "Mau beli Raw Manga dari Jepang atau Manhwa dari Korea? Cek estimasi harganya di sini."),
          const SizedBox(height: 25),

          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: "Masukkan Harga",
              labelStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.attach_money, color: Colors.blueAccent),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[800]!),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blueAccent),
              ),
              filled: true,
              fillColor: Colors.grey[900],
            ),
            onChanged: (val) => _convert(),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: _buildDropdown("Dari", _fromCurrency, (val) {
                setState(() => _fromCurrency = val!);
                _convert();
              })),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward, color: Colors.grey),
              ),
              Expanded(child: _buildDropdown("Ke", _toCurrency, (val) {
                setState(() => _toCurrency = val!);
                _convert();
              })),
            ],
          ),
          
          const SizedBox(height: 30),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue[900]!, Colors.blue[800]!]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10)],
            ),
            child: Column(
              children: [
                const Text("Estimasi Harga:", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                Text(
                  NumberFormat.currency(
                    locale: 'id', 
                    symbol: _toCurrency == 'IDR' ? 'Rp ' : '$_toCurrency ', 
                    decimalDigits: 2
                  ).format(_result),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: Colors.grey[900],
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: _rates.keys.map((String key) {
                return DropdownMenuItem<String>(
                  value: key,
                  child: Text(key),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      ],
    );
  }
}

// ==========================================
// TAB 2: JAM DUNIA (JADWAL RILIS) - UPDATED 🛠️
// ==========================================
class WorldClockView extends StatefulWidget {
  const WorldClockView({super.key});

  @override
  State<WorldClockView> createState() => _WorldClockViewState();
}

class _WorldClockViewState extends State<WorldClockView> {
  late Timer _timer;
  DateTime _now = DateTime.now().toUtc();
  bool _isLocaleInitialized = false; // Flag penanda

  @override
  void initState() {
    super.initState();
    // 1. Inisialisasi Data Bahasa Indonesia dulu
    initializeDateFormatting('id_ID', null).then((_) {
      if (mounted) {
        setState(() {
          _isLocaleInitialized = true; // Tandai sudah siap
        });
      }
    });

    // 2. Jalankan Timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now().toUtc();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 3. Cek: Jangan render dulu kalau Locale belum siap
    if (!_isLocaleInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeader("Jadwal Rilis Global 🌍", "Pantau waktu server Jepang (Manga), Korea (Manhwa), dan London (Global) agar tidak ketinggalan update."),
        const SizedBox(height: 20),

        _buildClockCard("WIB (Indonesia Barat)", "Server Lokal", _now.add(const Duration(hours: 7)), Colors.blue),
        _buildClockCard("WITA (Indonesia Tengah)", "Server Lokal", _now.add(const Duration(hours: 8)), Colors.cyan),
        _buildClockCard("WIT (Indonesia Timur)", "Server Lokal", _now.add(const Duration(hours: 9)), Colors.teal),
        const Divider(color: Colors.grey, height: 30),
        _buildClockCard("Tokyo, Jepang (JST)", "Pusat Manga 🇯🇵", _now.add(const Duration(hours: 9)), Colors.redAccent),
        _buildClockCard("Seoul, Korea (KST)", "Pusat Manhwa 🇰🇷", _now.add(const Duration(hours: 9)), Colors.pinkAccent),
        _buildClockCard("London, UK (GMT)", "Rilis Global 🇬🇧", _now.add(const Duration(hours: 0)), Colors.purpleAccent),
      ],
    );
  }

  Widget _buildClockCard(String city, String tag, DateTime time, Color color) {
    String formattedTime = DateFormat('HH:mm:ss').format(time);
    // Sekarang aman pakai 'id_ID' karena sudah di-init
    String date = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(time); 

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(city, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(tag, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
          Text(
            formattedTime,
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      ],
    );
  }
}