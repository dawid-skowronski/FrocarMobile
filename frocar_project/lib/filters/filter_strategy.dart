import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_project/models/car_listing.dart';

abstract class FilterStrategy {
  bool apply(CarListing listing);
}

class UserAndAvailabilityFilterStrategy implements FilterStrategy {
  final int? currentUserId;

  UserAndAvailabilityFilterStrategy(this.currentUserId);

  @override
  bool apply(CarListing listing) {
    return listing.userId != currentUserId && listing.isAvailable;
  }
}

class BrandFilterStrategy implements FilterStrategy {
  final String? brand;

  BrandFilterStrategy(this.brand);

  @override
  bool apply(CarListing listing) {
    if (brand == null || brand!.isEmpty) return true;
    return listing.brand.toLowerCase().contains(brand!.toLowerCase());
  }
}

class SeatsFilterStrategy implements FilterStrategy {
  final int? minSeats;
  final int? maxSeats;

  SeatsFilterStrategy(this.minSeats, this.maxSeats);

  @override
  bool apply(CarListing listing) {
    bool matches = true;
    if (minSeats != null) {
      matches = matches && listing.seats >= minSeats!;
    }
    if (maxSeats != null) {
      matches = matches && listing.seats <= maxSeats!;
    }
    return matches;
  }
}

class FuelTypeFilterStrategy implements FilterStrategy {
  final List<String> fuelTypes;

  FuelTypeFilterStrategy(this.fuelTypes);

  @override
  bool apply(CarListing listing) {
    if (fuelTypes.isEmpty) return true;
    return fuelTypes.contains(listing.fuelType);
  }
}

class PriceFilterStrategy implements FilterStrategy {
  final double? minPrice;
  final double? maxPrice;

  PriceFilterStrategy(this.minPrice, this.maxPrice);

  @override
  bool apply(CarListing listing) {
    bool matches = true;
    if (minPrice != null) {
      matches = matches && listing.rentalPricePerDay >= minPrice!;
    }
    if (maxPrice != null) {
      matches = matches && listing.rentalPricePerDay <= maxPrice!;
    }
    return matches;
  }
}

class CarTypeFilterStrategy implements FilterStrategy {
  final List<String> carTypes;

  CarTypeFilterStrategy(this.carTypes);

  @override
  bool apply(CarListing listing) {
    if (carTypes.isEmpty) return true;
    final lowerCaseCarTypes = carTypes.map((type) => type.toLowerCase()).toList();
    return lowerCaseCarTypes.contains(listing.carType.toLowerCase());
  }
}

class LocationFilterStrategy implements FilterStrategy {
  final LatLng? cityCoordinates;
  final double? radius;

  LocationFilterStrategy(this.cityCoordinates, this.radius);

  @override
  bool apply(CarListing listing) {
    if (cityCoordinates == null || radius == null) return true;
    final distance = Geolocator.distanceBetween(
      cityCoordinates!.latitude,
      cityCoordinates!.longitude,
      listing.latitude,
      listing.longitude,
    ) / 1000;
    return distance <= radius!;
  }
}