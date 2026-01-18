class StoreModel {
  final String name;
  final String address;
  final double rating;
  final double lat;
  final double lng;
  final bool isOpen;
  final String openHours;

  StoreModel({
    required this.name,
    required this.address,
    required this.rating,
    required this.lat,
    required this.lng,
    required this.isOpen,
    required this.openHours,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    // Ambil jam buka hari ini (indeks 0 atau default)
    String hours = "Jam buka tidak tersedia";
    bool openStatus = true; // Default

    if (json['openingHours'] != null && (json['openingHours'] as List).isNotEmpty) {
      hours = (json['openingHours'] as List).first.toString();
    }

    return StoreModel(
      name: json['name'] ?? "Gramedia",
      address: json['address'] ?? "Alamat tidak tersedia",
      // Konversi aman ke double
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      isOpen: openStatus,
      openHours: hours,
    );
  }
}