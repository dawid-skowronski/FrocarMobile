import 'package:flutter/material.dart';
import '/widgets/custom_app_bar.dart';
import '../models/car_listing.dart';

class CarListingDetailPage extends StatelessWidget {
  final CarListing listing;

  CarListingDetailPage({required this.listing});

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Color(0xFF375534);

    return Scaffold(
      appBar: const CustomAppBar(title: "Szczególy pojazdu"),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Szczegóły samochodu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Marka
                      ListTile(
                        leading: const Icon(Icons.directions_car, color: themeColor),
                        title: Text(
                          'Marka: ${listing.brand}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.directions_car_outlined, color: themeColor),
                        title: Text(
                          'Pojemność silnika: ${listing.engineCapacity} l',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      // Rodzaj paliwa
                      ListTile(
                        leading: const Icon(Icons.local_gas_station_outlined, color: themeColor),
                        title: Text(
                          'Rodzaj paliwa: ${listing.fuelType}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      // Liczba miejsc
                      ListTile(
                        leading: const Icon(Icons.event_seat, color: themeColor),
                        title: Text(
                          'Liczba miejsc: ${listing.seats}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      // Typ samochodu
                      ListTile(
                        leading: const Icon(Icons.car_rental, color: themeColor),
                        title: Text(
                          'Typ samochodu: ${listing.carType}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Sekcja dodatków
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dodatki',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: listing.features
                            .map(
                              (feature) => Chip(
                            label: Text(
                              feature,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: themeColor.withOpacity(0.8),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Sekcja lokalizacji
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lokalizacja',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(Icons.location_on, color: themeColor),
                        title: Text(
                          'Współrzędne: ${listing.latitude}, ${listing.longitude}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}