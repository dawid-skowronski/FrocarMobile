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
    return CarListingBuilder()
        .fromJson(json)
        .build();
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
    return CarListingBuilder()
        .setId(0)
        .setBrand('Brak danych')
        .setEngineCapacity(0.0)
        .setFuelType('Brak danych')
        .setSeats(0)
        .setCarType('Brak danych')
        .setFeatures([])
        .setLatitude(0.0)
        .setLongitude(0.0)
        .setUserId(0)
        .setIsAvailable(false)
        .setRentalPricePerDay(0.0)
        .setIsApproved(false)
        .setAverageRating(0.0)
        .build();
  }

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
    return CarListingBuilder()
        .setId(id ?? this.id)
        .setBrand(brand ?? this.brand)
        .setEngineCapacity(engineCapacity ?? this.engineCapacity)
        .setFuelType(fuelType ?? this.fuelType)
        .setSeats(seats ?? this.seats)
        .setCarType(carType ?? this.carType)
        .setFeatures(features ?? this.features)
        .setLatitude(latitude ?? this.latitude)
        .setLongitude(longitude ?? this.longitude)
        .setUserId(userId ?? this.userId)
        .setIsAvailable(isAvailable ?? this.isAvailable)
        .setRentalPricePerDay(rentalPricePerDay ?? this.rentalPricePerDay)
        .setIsApproved(isApproved ?? this.isApproved)
        .setAverageRating(averageRating ?? this.averageRating)
        .build();
  }
}

class CarListingBuilder {
  int? _id;
  String? _brand;
  double? _engineCapacity;
  String? _fuelType;
  int? _seats;
  String? _carType;
  List<String>? _features;
  double? _latitude;
  double? _longitude;
  int? _userId;
  bool? _isAvailable;
  double? _rentalPricePerDay;
  bool? _isApproved;
  double? _averageRating;

  CarListingBuilder setId(int id) {
    _id = id;
    return this;
  }

  CarListingBuilder setBrand(String brand) {
    _brand = brand;
    return this;
  }

  CarListingBuilder setEngineCapacity(double engineCapacity) {
    _engineCapacity = engineCapacity;
    return this;
  }

  CarListingBuilder setFuelType(String fuelType) {
    _fuelType = fuelType;
    return this;
  }

  CarListingBuilder setSeats(int seats) {
    _seats = seats;
    return this;
  }

  CarListingBuilder setCarType(String carType) {
    _carType = carType;
    return this;
  }

  CarListingBuilder setFeatures(List<String> features) {
    _features = features;
    return this;
  }

  CarListingBuilder setLatitude(double latitude) {
    _latitude = latitude;
    return this;
  }

  CarListingBuilder setLongitude(double longitude) {
    _longitude = longitude;
    return this;
  }

  CarListingBuilder setUserId(int userId) {
    _userId = userId;
    return this;
  }

  CarListingBuilder setIsAvailable(bool isAvailable) {
    _isAvailable = isAvailable;
    return this;
  }

  CarListingBuilder setRentalPricePerDay(double rentalPricePerDay) {
    _rentalPricePerDay = rentalPricePerDay;
    return this;
  }

  CarListingBuilder setIsApproved(bool isApproved) {
    _isApproved = isApproved;
    return this;
  }

  CarListingBuilder setAverageRating(double averageRating) {
    _averageRating = averageRating;
    return this;
  }

  CarListingBuilder fromJson(Map<String, dynamic> json) {
    _id = json['id'] ?? 0;
    _brand = json['brand'] ?? '';
    _engineCapacity = (json['engineCapacity'] as num?)?.toDouble() ?? 0.0;
    _fuelType = json['fuelType'] ?? '';
    _seats = json['seats'] ?? 0;
    _carType = json['carType'] ?? '';
    _features = List<String>.from(json['features'] ?? []);
    _latitude = (json['latitude'] as num?)?.toDouble() ?? 0.0;
    _longitude = (json['longitude'] as num?)?.toDouble() ?? 0.0;
    _userId = json['userId'] ?? 0;
    _isAvailable = json['isAvailable'] as bool? ?? false;
    _rentalPricePerDay = (json['rentalPricePerDay'] as num?)?.toDouble() ?? 0.0;
    _isApproved = json['isApproved'] as bool? ?? false;
    _averageRating = (json['averageRating'] as num?)?.toDouble() ?? 0.0;
    return this;
  }

  CarListing build() {
    if (_id == null ||
        _brand == null ||
        _engineCapacity == null ||
        _fuelType == null ||
        _seats == null ||
        _carType == null ||
        _features == null ||
        _latitude == null ||
        _longitude == null ||
        _userId == null ||
        _isAvailable == null ||
        _rentalPricePerDay == null ||
        _isApproved == null ||
        _averageRating == null) {
      throw StateError('All required fields must be set');
    }

    return CarListing(
      id: _id!,
      brand: _brand!,
      engineCapacity: _engineCapacity!,
      fuelType: _fuelType!,
      seats: _seats!,
      carType: _carType!,
      features: _features!,
      latitude: _latitude!,
      longitude: _longitude!,
      userId: _userId!,
      isAvailable: _isAvailable!,
      rentalPricePerDay: _rentalPricePerDay!,
      isApproved: _isApproved!,
      averageRating: _averageRating!,
    );
  }
}