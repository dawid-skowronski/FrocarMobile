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
  });

  factory CarListing.fromJson(Map<String, dynamic> json) {
    return CarListing(
      id: json['id'],
      brand: json['brand'],
      engineCapacity: json['engineCapacity'].toDouble(),
      fuelType: json['fuelType'],
      seats: json['seats'],
      carType: json['carType'],
      features: List<String>.from(json['features']),
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'brand': brand,
    'engineCapacity': engineCapacity,
    'fuelType': fuelType,
    'seats': seats,
    'carType': carType,
    'features': features,
    'latitude': latitude,
    'longitude': longitude,
  };
}