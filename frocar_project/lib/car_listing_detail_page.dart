import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '/widgets/custom_app_bar.dart';
import '../models/car_listing.dart';
import '../models/car_rental_review.dart';
import '../services/api_service.dart';
import 'rent_form_page.dart';
import 'car_listing_page.dart';
import 'car_reviews_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CarListingDetailPage extends StatelessWidget {
  final CarListing listing;

  const CarListingDetailPage({super.key, required this.listing});

  Future<String> getAddressFromCoordinates(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1',
      );
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
          return 'Nieznany adres';
        }
      } else {
        return 'Błąd pobierania adresu (${response.statusCode})';
      }
    } catch (e) {
      return 'Błąd połączenia z serwerem lokalizacji';
    }
  }

  Future<int?> getCurrentUserId(BuildContext context) async {
    final storage = Provider.of<FlutterSecureStorage>(context, listen: false);
    final token = await storage.read(key: 'token');
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length != 3) throw Exception('Nieprawidłowy token JWT');
        final payload = parts[1];
        final decodedPayload = utf8.decode(base64.decode(base64.normalize(payload)));
        final decoded = jsonDecode(decodedPayload) as Map<String, dynamic>;
        final userId = int.parse(
          decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ?? '0',
        );
        return userId;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> _deleteListing(BuildContext context) async {
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      await api.deleteCarListing(listing.id);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nie udało się usunąć pojazdu. Spróbuj ponownie później.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Potwierdzenie',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF375534)),
        ),
        content: const Text('Czy na pewno chcesz usunąć ten pojazd?', style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteListing(context);
            },
            child: const Text('Usuń', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Color(0xFF375534);

    return Scaffold(
      appBar: CustomAppBar(
        title: "Szczegóły pojazdu",
        onNotificationPressed: () => Navigator.pushNamed(context, '/notifications'),
      ),
      body: FutureBuilder<int?>(
        future: getCurrentUserId(context),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentUserId = userSnapshot.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Szczegóły samochodu',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: themeColor)),
                        const SizedBox(height: 8),
                        ListTile(leading: const Icon(Icons.directions_car, color: themeColor), title: Text('Marka: ${listing.brand}')),
                        ListTile(leading: const Icon(Icons.directions_car_outlined, color: themeColor), title: Text('Pojemność silnika: ${listing.engineCapacity} l')),
                        ListTile(leading: const Icon(Icons.local_gas_station_outlined, color: themeColor), title: Text('Rodzaj paliwa: ${listing.fuelType}')),
                        ListTile(leading: const Icon(Icons.event_seat, color: themeColor), title: Text('Liczba miejsc: ${listing.seats}')),
                        ListTile(leading: const Icon(Icons.car_rental, color: themeColor), title: Text('Typ samochodu: ${listing.carType}')),
                        ListTile(leading: const Icon(Icons.attach_money, color: themeColor), title: Text('Cena wynajmu za dzień: ${listing.rentalPricePerDay.toStringAsFixed(2)} PLN')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dodatki',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: themeColor)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: listing.features
                              .map((f) => Chip(
                            label: Text(f, style: const TextStyle(color: Colors.white)),
                            backgroundColor: themeColor.withOpacity(0.8),
                          ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Lokalizacja',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: themeColor)),
                      const SizedBox(height: 8),
                      FutureBuilder<String>(
                        future: getAddressFromCoordinates(listing.latitude, listing.longitude),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return const Text(
                              'Nie udało się pobrać lokalizacji pojazdu. Sprawdź połączenie z internetem.',
                              style: TextStyle(color: Colors.red),
                            );
                          } else {
                            return ListTile(
                              leading: const Icon(Icons.location_on, color: themeColor),
                              title: Text('Adres: ${snapshot.data}', style: const TextStyle(fontSize: 16)),
                            );
                          }
                        },
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Recenzje',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: themeColor)),
                      const SizedBox(height: 8),
                      FutureBuilder<List<CarRentalReview>>(
                        future: Provider.of<ApiService>(context, listen: false).getReviewsForListing(listing.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return const Text(
                              'Nie udało się załadować danych. Spróbuj ponownie później.',
                              style: TextStyle(color: Colors.red),
                            );
                          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            final reviews = snapshot.data!;
                            final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
                            final latest = reviews.isNotEmpty ? reviews.first : null;
                            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                const Icon(Icons.star, color: Colors.amber, size: 24),
                                const SizedBox(width: 8),
                                Text('Średnia ocena: ${avg.toStringAsFixed(1)} (${reviews.length} opinii)'),
                              ]),
                              const SizedBox(height: 16),
                              if (latest != null) ...[
                                const Text('Najnowsza opinia:',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(latest.comment ?? 'Brak komentarza',
                                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(
                                    'Autor: ${latest.user.username} (${latest.createdAt.toString().substring(0, 10)})',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                              const SizedBox(height: 16),
                              Center(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => CarReviewsPage(listingId: listing.id)),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Więcej', style: TextStyle(fontSize: 16, color: Colors.white)),
                                ),
                              ),
                            ]);
                          } else {
                            return const Text(
                              'Ten pojazd nie ma jeszcze żadnych opinii.\nBądź pierwszym, który go oceni!',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                              textAlign: TextAlign.center,
                            );
                          }
                        },
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),

                Center(
                  child: Column(
                    children: [
                      if (currentUserId != null && listing.userId != currentUserId && listing.isAvailable)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => RentFormPage(listing: listing)),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Wypożycz', style: TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      if (currentUserId != null && listing.userId != currentUserId && !listing.isAvailable)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Ten pojazd jest obecnie niedostępny do wypożyczenia.',
                            style: TextStyle(fontSize: 16, color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (currentUserId != null && listing.userId == currentUserId)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => CarListingPage(listing: listing)),
                                ).then((result) {
                                  if (result == true) Navigator.pop(context, true);
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Edytuj', style: TextStyle(fontSize: 16, color: Colors.white)),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () => _showDeleteConfirmationDialog(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Usuń', style: TextStyle(fontSize: 16, color: Colors.white)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
