import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../models/store_model.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  final Dio _dio = Dio();
  final String _apiUrl = "https://yrizzz.my.id/api/v1/maps/gmaps";

  Future<List<StoreModel>> searchNearbyStores(Position userPos) async {
    try {
      // 🔥 UPDATE: Gunakan Koordinat User untuk Query Spesifik 🔥
      // Ini akan membuat API mencari: "Gramedia near -7.7956,110.3695" (Contoh)
      // Hasilnya setara dengan mencari "Gramedia area Jogja" jika kamu di Jogja.
      final String dynamicQuery = "Gramedia near ${userPos.latitude},${userPos.longitude}";
      
      // Print untuk debugging agar kamu bisa lihat di console query apa yang dikirim
      print("🔎 Searching API with query: $dynamicQuery");

      final response = await _dio.get(
        _apiUrl,
        queryParameters: {
          'query': dynamicQuery, // Gunakan query dinamis ini
        },
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        final List rawData = response.data['data'];
        List<StoreModel> stores = rawData.map((e) => StoreModel.fromJson(e)).toList();

        // 🔥 LOGIKA LBS (Location Based Service) 🔥
        // Kita urutkan manual lagi berdasarkan jarak real-time dari user
        // Agar yang paling dekat muncul paling atas (atau marker paling relevan)
        stores.sort((a, b) {
          double distA = Geolocator.distanceBetween(userPos.latitude, userPos.longitude, a.lat, a.lng);
          double distB = Geolocator.distanceBetween(userPos.latitude, userPos.longitude, b.lat, b.lng);
          return distA.compareTo(distB);
        });

        return stores;
      }
      return [];
    } catch (e) {
      print("❌ Error Location API: $e");
      return [];
    }
  }

  // Helper untuk hitung jarak (return String km/m)
  // Dipakai untuk menampilkan label jarak di UI jika diperlukan
  String calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    double distanceInMeters = Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
    if (distanceInMeters < 1000) {
      return "${distanceInMeters.toStringAsFixed(0)} m";
    } else {
      return "${(distanceInMeters / 1000).toStringAsFixed(1)} km";
    }
  }

  Future<List<LatLng>> getRoute(double startLat, double startLng, double endLat, double endLng) async {
    try {
      // URL OSRM (Gratis & Public)
      final String url = 
          "http://router.project-osrm.org/route/v1/driving/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson";

      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['routes'] == null || (data['routes'] as List).isEmpty) return [];

        // Ambil koordinat dari GeoJSON
        final List coordinates = data['routes'][0]['geometry']['coordinates'];
        
        // Konversi ke format LatLng yg dipakai flutter_map
        // Note: OSRM formatnya [Longitude, Latitude] (terbalik)
        return coordinates.map((coord) {
          return LatLng(coord[1].toDouble(), coord[0].toDouble());
        }).toList();
      }
      return [];
    } catch (e) {
      print("❌ Error Fetching Route: $e");
      return [];
    }
  }

}