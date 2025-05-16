import 'package:flutter/material.dart';
import '/widgets/custom_app_bar.dart';
import '../models/car_listing.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'rent_form_page.dart';
import 'car_listing_page.dart';
import '../services/api_service.dart';
import '../models/car_rental_review.dart';
import 'car_reviews_page.dart';

class CarListingDetailPage extends StatelessWidget {
  final CarListing listing;
  final _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();

  CarListingDetailPage({super.key, required this.listing});

  Future<String> getAddressFromCoordinates(double lat, double lon) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1');
    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'FrogCarApp/1.0 (jakub.trznadel@studenci.collegiumwitelona.pl)',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final address = data['address'];
      if (address != null) {
        final street = address['road'] ?? '';
        final houseNumber = address['house_number'] ?? '';
        final state = address['state'] ?? '';
        final city = address['city'] ?? address['town'] ?? address['village'] ?? '';
        final postcode = address['postcode'] ?? '';
        return '$street $houseNumber, $state, $city, $postcode'.trim();
      } else {
        return 'Nie znaleziono adresu';
      }
    } else {
      throw Exception('Błąd: ${response.statusCode}');
    }
  }

  Future<int?> getCurrentUserId() async {
    final token = await _storage.read(key: 'token');
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length != 3) {
          throw Exception('Nieprawidłowy token JWT');
        }
        final payload = parts[1];
        final decodedPayload = utf8.decode(base64.decode(base64.normalize(payload)));
        final decoded = jsonDecode(decodedPayload) as Map<String, dynamic>;
        final userId = int.parse(
            decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ?? '0');
        return userId;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Color(0xFF375534);

    return Scaffold(
      appBar: CustomAppBar(
        title: "Szczegóły pojazdu",
        onNotificationPressed: () {
          Navigator.pushNamed(context, '/notifications');
        },
      ),
      body: FutureBuilder<int?>(
        future: getCurrentUserId(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentUserId = userSnapshot.data;

          return SingleChildScrollView(
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
                          ListTile(
                            leading: const Icon(Icons.local_gas_station_outlined, color: themeColor),
                            title: Text(
                              'Rodzaj paliwa: ${listing.fuelType}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.event_seat, color: themeColor),
                            title: Text(
                              'Liczba miejsc: ${listing.seats}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.car_rental, color: themeColor),
                            title: Text(
                              'Typ samochodu: ${listing.carType}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.attach_money, color: themeColor),
                            title: Text(
                              'Cena wynajmu za dzień: ${listing.rentalPricePerDay.toStringAsFixed(2)} PLN',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                          FutureBuilder<String>(
                            future: getAddressFromCoordinates(listing.latitude, listing.longitude),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Text(
                                  'Błąd: ${snapshot.error.toString().replaceFirst('Exception: ', '')}',
                                  style: const TextStyle(color: Colors.red),
                                );
                              } else if (snapshot.hasData) {
                                return ListTile(
                                  leading: const Icon(Icons.location_on, color: themeColor),
                                  title: Text(
                                    'Adres: ${snapshot.data}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                );
                              } else {
                                return const Text('Nie udało się pobrać adresu');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                            'Recenzje',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: themeColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<List<CarRentalReview>>(
                            future: _apiService.getReviewsForListing(listing.id),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Text(
                                  'Błąd: ${snapshot.error.toString().replaceFirst('Exception: ', '')}',
                                  style: const TextStyle(color: Colors.red),
                                );
                              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                final reviews = snapshot.data!;
                                final averageRating = reviews.isNotEmpty
                                    ? reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length
                                    : 0.0;
                                final latestReview = reviews.first;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 24),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Średnia ocena: ${averageRating.toStringAsFixed(1)} (${reviews.length} opinii)',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Najnowsza opinia:',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      latestReview.comment ?? 'Brak komentarza',
                                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Autor: ${latestReview.user.username} (${latestReview.createdAt.toString().substring(0, 10)})',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 16),
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CarReviewsPage(listingId: listing.id),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: themeColor,
                                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text(
                                          'Więcej',
                                          style: TextStyle(fontSize: 16, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                return const Text(
                                  'Brak recenzji dla tego pojazdu.',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        if (currentUserId != null &&
                            listing.userId != currentUserId &&
                            listing.isAvailable)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RentFormPage(listing: listing),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Wypożycz',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        if (currentUserId != null && listing.userId == currentUserId)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CarListingPage(listing: listing),
                                ),
                              ).then((result) {
                                if (result == true) {
                                  Navigator.pop(context, true);
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Edytuj',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}