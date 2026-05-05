import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart'; 
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../models/store_model.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  
  LatLng _center = const LatLng(-7.7956, 110.3695); // Default Jogja
  List<StoreModel> _stores = [];
  bool _isLoading = true;
  Position? _currentPosition;

  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    
    if(mounted) {
      setState(() {
        _currentPosition = position;
        _center = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_center, 14.0);
      _fetchNearbyStores(position);
    }
  }

  Future<void> _fetchNearbyStores(Position userPos) async {
    try {
      final stores = await _locationService.searchNearbyStores(userPos);
      if (mounted) {
        setState(() {
          _stores = stores;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching stores: $e");
    }
  }

  Future<void> _drawRoute(double destLat, double destLng) async {
    if (_currentPosition == null) return;
    Navigator.pop(context); 
    setState(() => _isLoading = true);

    final route = await _locationService.getRoute(
      _currentPosition!.latitude, 
      _currentPosition!.longitude, 
      destLat, 
      destLng
    );

    setState(() {
      _routePoints = route; 
      _isLoading = false;
    });

    if (route.isNotEmpty) {
       _mapController.move(LatLng(destLat, destLng), 13.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LocationScreenColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. HEADER SECTION (Kata-kata Menarik) ---
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.menu_book_rounded, color: LocationScreenColors.headerIcon, size: 28),
                      SizedBox(width: 10),
                      Expanded(
                        child: const Text(
                          "Gramedia Terdekat 📖", 
                          style: TextStyle(
                            color: LocationScreenColors.headerTitle, 
                            fontSize: 22, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Lelah menatap layar HP? Sentuhlah rumput. Temukan toko buku & komik terdekat dan nikmati aroma kertas yang khas!",
                    style: TextStyle(
                      color: LocationScreenColors.headerSubtitle, 
                      fontSize: 14,
                      height: 1.5
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. MAP SECTION (Rounded & Expanded) ---
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16), // Memberi jarak dari tepi
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25), // Sudut membulat
                  border: Border.all(color: LocationScreenColors.mapBorder, width: 2), // Border tipis
                  boxShadow: [
                    BoxShadow(
                      color: LocationScreenColors.mapGlow.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: ClipRRect( // Memotong peta agar mengikuti sudut container
                  borderRadius: BorderRadius.circular(23),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _center,
                          initialZoom: 13.0,
                          backgroundColor: LocationScreenColors.mapLoading,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.rex4red.manga',
                          ),

                          // Layer Rute
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                strokeWidth: 5.0,
                                color: LocationScreenColors.routeLine,
                              ),
                            ],
                          ),

                          // Layer Marker
                          MarkerLayer(
                            markers: [
                              // User
                              if (_currentPosition != null)
                                Marker(
                                  point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                  width: 40, height: 40,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: LocationScreenColors.userMarkerBg.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.my_location, color: LocationScreenColors.userMarkerIcon, size: 25),
                                  ),
                                ),

                              // Toko
                              ..._stores.map((store) => Marker(
                                    point: LatLng(store.lat, store.lng),
                                    width: 45, height: 45,
                                    child: GestureDetector(
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) => _buildStoreInfo(store),
                                        );
                                      },
                                      child: Icon(Icons.location_on, color: LocationScreenColors.storeMarker, size: 45),
                                    ),
                                  )),
                            ],
                          ),
                        ],
                      ),

                      // Loading Overlay Kecil
                      if (_isLoading)
                        Positioned(
                          top: 15, left: 15,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: LocationScreenColors.loadingOverlay,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: LocationScreenColors.loadingSpinner)),
                                const SizedBox(width: 8),
                                const Text("Mencari Gramedia...", style: TextStyle(color: LocationScreenColors.loadingText, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),

                      // Tombol Lokasi Saya (Floating di dalam Map)
                      Positioned(
                        bottom: 20, right: 20,
                        child: FloatingActionButton.small(
                          onPressed: () {
                            if (_currentPosition != null) {
                              _mapController.move(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 15.0);
                              setState(() => _routePoints = []);
                            } else {
                              _getUserLocation();
                            }
                          },
                          backgroundColor: LocationScreenColors.gpsFabBg,
                          child: Icon(Icons.gps_fixed, color: LocationScreenColors.gpsFabIcon),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Info Toko (Desain Modern)
  Widget _buildStoreInfo(StoreModel store) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: LocationScreenColors.sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: LocationScreenColors.sheetShadow, blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Agar tinggi menyesuaikan konten
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle Bar (Garis kecil di atas)
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: LocationScreenColors.sheetHandle, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          
          Text(store.name, style: TextStyle(color: LocationScreenColors.storeName, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: LocationScreenColors.storeAddress, size: 16),
              const SizedBox(width: 5),
              Expanded(child: Text(store.address, style: TextStyle(color: LocationScreenColors.storeAddress), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          
          const SizedBox(height: 15),
          
          // Info Grid (Rating & Jam)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(store.rating.toString(), style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.green, size: 18),
                    const SizedBox(width: 4),
                    Text(store.openHours, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 25),
          
          // Tombol Rute Lebar
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _drawRoute(store.lat, store.lng),
              style: ElevatedButton.styleFrom(
                backgroundColor: LocationScreenColors.routeButtonBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 5,
              ),
              icon: Icon(Icons.directions, color: LocationScreenColors.routeButtonText),
              label: Text("Tunjukkan Rute Jalan", style: TextStyle(color: LocationScreenColors.routeButtonText, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}

class LocationScreenColors {
  static const background       = Color.fromARGB(255, 49, 48, 48);        // Background utama
  static const headerIcon       = Colors.blueAccent;   // Ikon buku di header
  static const headerTitle      = Colors.white;        // Judul "Gramedia Terdekat"
  static final headerSubtitle   = Colors.grey[400];    // Teks deskripsi header
  static final mapBorder        = Colors.grey[800]!;   // Border kotak peta
  static const mapGlow          = Colors.blueAccent;   // Glow shadow di peta
  static final mapLoading       = Colors.grey[900]!;   // Warna peta saat loading tile
  static const routeLine        = Colors.blueAccent;   // Garis rute jalan
  static const userMarkerBg     = Colors.blueAccent;   // Lingkaran marker user
  static const userMarkerIcon   = Colors.blueAccent;   // Ikon my_location user
  static const storeMarker      = Colors.redAccent;    // Pin marker toko
  static const loadingOverlay   = Colors.black87;      // Background overlay loading
  static const loadingSpinner   = Colors.white;        // Spinner loading
  static const loadingText      = Colors.white;        // Teks "Mencari Gramedia..."
  static const gpsFabBg         = Colors.blueAccent;   // Background FAB GPS
  static const gpsFabIcon       = Colors.white;        // Ikon FAB GPS
  static final sheetBg          = Colors.grey[900];    // Background bottom sheet toko
  static final sheetShadow      = Colors.black.withOpacity(0.5); // Shadow sheet
  static final sheetHandle      = Colors.grey[700];    // Handle bar atas sheet
  static const storeName        = Colors.white;        // Nama toko
  static const storeAddress     = Colors.grey;         // Alamat & ikon toko
  static const routeButtonBg    = Colors.blueAccent;   // Background tombol rute
  static const routeButtonText  = Colors.white;        // Teks & ikon tombol rute
}