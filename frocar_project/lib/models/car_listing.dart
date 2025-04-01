class CarListing {
  final int id;
  final String brand;
  final double engineCapacity;
  final String fuelType;
  final int seats;
  final String carType;
  final List<String> features;
  final double latitude;
  final double longitude;
  final int userId;
  final bool isAvailable;
  final double rentalPricePerDay;

  CarListing({
    required this.id,
    required this.brand,
    required this.engineCapacity,
    required this.fuelType,
    required this.seats,
    required this.carType,
    required this.features,
    required this.latitude,
    required this.longitude,
    required this.userId,
    required this.isAvailable,
    required this.rentalPricePerDay,
  });

  factory CarListing.fromJson(Map<String, dynamic> json) {
    return CarListing(
      id: json['id'] ?? 0,
      brand: json['brand'] ?? '',
      engineCapacity: (json['engineCapacity'] as num?)?.toDouble() ?? 0.0,
      fuelType: json['fuelType'] ?? '',
      seats: json['seats'] ?? 0,
      carType: json['carType'] ?? '',
      features: List<String>.from(json['features'] ?? []),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      userId: json['userId'] ?? 0,
      isAvailable: json['isAvailable'] ?? false,
      rentalPricePerDay: (json['rentalPricePerDay'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand': brand,
      'engineCapacity': engineCapacity,
      'fuelType': fuelType,
      'seats': seats,
      'carType': carType,
      'features': features,
      'latitude': latitude,
      'longitude': longitude,
      'userId': userId,
      'isAvailable': isAvailable,
      'rentalPricePerDay': rentalPricePerDay,
    };
  }
}