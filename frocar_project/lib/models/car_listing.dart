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
  final bool isApproved;
  final double averageRating;

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
    required this.isApproved,
    required this.averageRating,
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
      isAvailable: json['isAvailable'] as bool? ?? false,
      rentalPricePerDay: (json['rentalPricePerDay'] as num?)?.toDouble() ?? 0.0,
      isApproved: json['isApproved'] as bool? ?? false,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
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
      'isApproved': isApproved,
      'averageRating': averageRating,
    };
  }

  factory CarListing.placeholder() {
    return CarListing(
      id: 0,
      brand: 'Brak danych',
      engineCapacity: 0.0,
      fuelType: 'Brak danych',
      seats: 0,
      carType: 'Brak danych',
      features: [],
      latitude: 0.0,
      longitude: 0.0,
      userId: 0,
      isAvailable: false,
      rentalPricePerDay: 0.0,
      isApproved: false,
      averageRating: 0.0,
    );
  }

  // 🔁 Metoda copyWith
  CarListing copyWith({
    int? id,
    String? brand,
    double? engineCapacity,
    String? fuelType,
    int? seats,
    String? carType,
    List<String>? features,
    double? latitude,
    double? longitude,
    int? userId,
    bool? isAvailable,
    double? rentalPricePerDay,
    bool? isApproved,
    double? averageRating,
  }) {
    return CarListing(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      engineCapacity: engineCapacity ?? this.engineCapacity,
      fuelType: fuelType ?? this.fuelType,
      seats: seats ?? this.seats,
      carType: carType ?? this.carType,
      features: features ?? this.features,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      userId: userId ?? this.userId,
      isAvailable: isAvailable ?? this.isAvailable,
      rentalPricePerDay: rentalPricePerDay ?? this.rentalPricePerDay,
      isApproved: isApproved ?? this.isApproved,
      averageRating: averageRating ?? this.averageRating,
    );
  }
}
