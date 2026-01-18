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
      backgroundColor: Colors.black, // Background Utama Gelap
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
                      Icon(Icons.menu_book_rounded, color: Colors.blueAccent, size: 28),
                      SizedBox(width: 10),
                      Expanded(
                        child: const Text(
                          "Gramedia Terdekat 📖", 
                          style: TextStyle(
                            color: Colors.white, 
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
                      color: Colors.grey[400], 
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
                  border: Border.all(color: Colors.grey[800]!, width: 2), // Border tipis
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.15),
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
                          backgroundColor: Colors.grey[900]!, // Warna dasar saat loading tile
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
                                color: Colors.blueAccent,
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
                                      color: Colors.blueAccent.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.my_location, color: Colors.blueAccent, size: 25),
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
                                      child: const Icon(Icons.location_on, color: Colors.redAccent, size: 45),
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
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                const SizedBox(width: 8),
                                const Text("Mencari Gramedia...", style: TextStyle(color: Colors.white, fontSize: 12)),
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
                          backgroundColor: Colors.blueAccent,
                          child: const Icon(Icons.gps_fixed, color: Colors.white),
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
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
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
              decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(10)),
            ),
          ),
          
          Text(store.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.grey, size: 16),
              const SizedBox(width: 5),
              Expanded(child: Text(store.address, style: const TextStyle(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 5,
              ),
              icon: const Icon(Icons.directions, color: Colors.white),
              label: const Text("Tunjukkan Rute Jalan", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}