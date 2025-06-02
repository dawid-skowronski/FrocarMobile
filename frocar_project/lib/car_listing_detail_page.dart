import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../widgets/custom_app_bar.dart';
import '../models/car_listing.dart';
import '../models/car_rental_review.dart';
import '../services/api_service.dart';
import 'rent_form_page.dart';
import 'car_listing_page.dart';
import 'car_reviews_page.dart';

const String _appBarTitle = "Szczegóły pojazdu";
const String _carDetailsTitle = 'Szczegóły samochodu';
const String _brandLabel = 'Marka:';
const String _engineCapacityLabel = 'Pojemność silnika:';
const String _fuelTypeLabel = 'Rodzaj paliwa:';
const String _seatsLabel = 'Liczba miejsc:';
const String _carTypeLabel = 'Typ samochodu:';
const String _rentalPriceLabel = 'Cena wynajmu za dzień:';
const String _featuresTitle = 'Dodatki';
const String _locationTitle = 'Lokalizacja';
const String _addressLabel = 'Adres:';
const String _unknownAddress = 'Nieznany adres';
const String _addressFetchError = 'Błąd pobierania adresu';
const String _locationConnectionError = 'Błąd połączenia z serwerem lokalizacji';
const String _locationFetchFailed = 'Nie udało się pobrać lokalizacji pojazdu. Sprawdź połączenie z internetem.';
const String _reviewsTitle = 'Recenzje';
const String _reviewsLoadError = 'Nie udało się załadować danych. Spróbuj ponownie później.';
const String _averageRatingLabel = 'Średnia ocena:';
const String _latestReviewTitle = 'Najnowsza opinia:';
const String _noComment = 'Brak komentarza';
const String _authorLabel = 'Autor:';
const String _moreReviewsButton = 'Więcej';
const String _noReviewsYet = 'Ten pojazd nie ma jeszcze żadnych opinii.';
const String _rentButton = 'Wypożycz';
const String _notAvailableMessage = 'Ten pojazd jest obecnie niedostępny do wypożyczenia.';
const String _editButton = 'Edytuj';
const String _deleteButton = 'Usuń';
const String _deleteConfirmationTitle = 'Potwierdzenie';
const String _deleteConfirmationContent = 'Czy na pewno chcesz usunąć ten pojazd?';
const String _cancelButton = 'Anuluj';
const String _deleteFailedMessage = 'Nie udało się usunąć pojazdu. Spróbuj ponownie później.';
const String _jwtTokenError = 'Nieprawidłowy token JWT';

class CarListingDetailPage extends StatelessWidget {
  final CarListing listing;

  const CarListingDetailPage({super.key, required this.listing});

  Future<String> _getAddressFromCoordinates(double lat, double lon) async {
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
          return _unknownAddress;
        }
      } else {
        return '$_addressFetchError (${response.statusCode})';
      }
    } catch (e) {
      return _locationConnectionError;
    }
  }

  Future<int?> _getCurrentUserId(BuildContext context) async {
    final storage = Provider.of<FlutterSecureStorage>(context, listen: false);
    final token = await storage.read(key: 'token');
    if (token == null) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) throw Exception(_jwtTokenError);
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

  Future<void> _deleteListing(BuildContext context) async {
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      await api.deleteCarListing(listing.id);
      if (context.mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, _deleteFailedMessage, Colors.red);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          _deleteConfirmationTitle,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF375534)),
        ),
        content: const Text(_deleteConfirmationContent, style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(_cancelButton, style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteListing(context);
            },
            child: const Text(_deleteButton, style: TextStyle(color: Colors.red)),
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
        title: _appBarTitle,
        onNotificationPressed: () => Navigator.pushNamed(context, '/notifications'),
      ),
      body: FutureBuilder<int?>(
        future: _getCurrentUserId(context),
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
                _buildCarDetailsCard(themeColor),
                const SizedBox(height: 16),
                _buildFeaturesCard(themeColor),
                const SizedBox(height: 16),
                _buildLocationCard(themeColor),
                const SizedBox(height: 16),
                _buildReviewsCard(themeColor, context),
                const SizedBox(height: 16),
                _buildActionButtons(context, currentUserId, themeColor),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCarDetailsCard(Color themeColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_carDetailsTitle,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: themeColor)),
            const SizedBox(height: 8),
            _buildDetailTile(Icons.directions_car, _brandLabel, listing.brand, themeColor),
            _buildDetailTile(Icons.directions_car_outlined, _engineCapacityLabel, '${listing.engineCapacity} l', themeColor),
            _buildDetailTile(Icons.local_gas_station_outlined, _fuelTypeLabel, listing.fuelType, themeColor),
            _buildDetailTile(Icons.event_seat, _seatsLabel, listing.seats.toString(), themeColor),
            _buildDetailTile(Icons.car_rental, _carTypeLabel, listing.carType, themeColor),
            _buildDetailTile(Icons.attach_money, _rentalPriceLabel, '${listing.rentalPricePerDay.toStringAsFixed(2)} PLN', themeColor),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text('$label $value'),
    );
  }

  Widget _buildFeaturesCard(Color themeColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_featuresTitle,
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
    );
  }

  Widget _buildLocationCard(Color themeColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_locationTitle,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: themeColor)),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: _getAddressFromCoordinates(listing.latitude, listing.longitude),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Text(
                    _locationFetchFailed,
                    style: TextStyle(color: Colors.red),
                  );
                } else {
                  return _buildDetailTile(Icons.location_on, _addressLabel, snapshot.data!, themeColor);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsCard(Color themeColor, BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_reviewsTitle,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: themeColor)),
            const SizedBox(height: 8),
            FutureBuilder<List<CarRentalReview>>(
              future: Provider.of<ApiService>(context, listen: false).getReviewsForListing(listing.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Text(
                    _reviewsLoadError,
                    style: TextStyle(color: Colors.red),
                  );
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final reviews = snapshot.data!;
                  final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
                  final latest = reviews.isNotEmpty ? reviews.first : null;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 24),
                          const SizedBox(width: 8),
                          Text('$_averageRatingLabel ${avg.toStringAsFixed(1)} (${reviews.length} opinii)'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (latest != null) _buildLatestReviewSection(latest),
                      const SizedBox(height: 16),
                      _buildMoreReviewsButton(context, themeColor),
                    ],
                  );
                } else {
                  return const Text(
                    _noReviewsYet,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestReviewSection(CarRentalReview latest) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(_latestReviewTitle,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(latest.comment ?? _noComment,
            style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
            '$_authorLabel ${latest.user.username} (${latest.createdAt.toString().substring(0, 10)})',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMoreReviewsButton(BuildContext context, Color themeColor) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CarReviewsPage(listingId: listing.id)),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(_moreReviewsButton, style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, int? currentUserId, Color themeColor) {
    return Center(
      child: Column(
        children: [
          if (currentUserId != null && listing.userId != currentUserId && listing.isAvailable)
            _buildRentButton(context, themeColor),
          if (currentUserId != null && listing.userId != currentUserId && !listing.isAvailable)
            _buildNotAvailableMessage(),
          if (currentUserId != null && listing.userId == currentUserId)
            _buildOwnerActions(context, themeColor),
        ],
      ),
    );
  }

  Widget _buildRentButton(BuildContext context, Color themeColor) {
    return ElevatedButton(
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RentFormPage(listing: listing)),
        );
        if (result == true) {
          if (context.mounted) {
            Navigator.pop(context, true);
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: themeColor,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(_rentButton, style: TextStyle(fontSize: 16, color: Colors.white)),
    );
  }

  Widget _buildNotAvailableMessage() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Text(
        _notAvailableMessage,
        style: TextStyle(fontSize: 16, color: Colors.redAccent),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildOwnerActions(BuildContext context, Color themeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CarListingPage(listing: listing)),
            ).then((result) {
              if (result == true) {
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              }
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(_editButton, style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () => _showDeleteConfirmationDialog(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(_deleteButton, style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ],
    );
  }
}
