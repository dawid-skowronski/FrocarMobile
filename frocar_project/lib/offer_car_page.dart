import 'package:flutter/material.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/models/car_listing.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'car_listing_page.dart' as listingPage; // Alias dla car_listing_page.dart
import 'car_listing_detail_page.dart' as detailPage; // Alias dla car_listing_detail_page.dart

class OfferCarPage extends StatefulWidget {
  const OfferCarPage({super.key});

  @override
  _OfferCarPageState createState() => _OfferCarPageState();
}

class _OfferCarPageState extends State<OfferCarPage> {
  final ApiService _apiService = ApiService();
  List<CarListing> _userListings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserListings();
  }

  Future<void> _loadUserListings() async {
    try {
      final listings = await _apiService.getUserCarListings();
      setState(() {
        _userListings = listings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _userListings = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Zarządzaj ogłoszeniami"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel "Dodaj nowe ogłoszenie"
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const listingPage.CarListingPage()),
                ).then((result) {
                  if (result == true) {
                    _loadUserListings(); // Odśwież listę tylko, jeśli dodano ogłoszenie
                  }
                });
              },
              child: Card(
                color: const Color(0xFF375534),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add, size: 32, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Dodaj nowe ogłoszenie',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Panel "Moje ogłoszenia"
            const Text(
              'Moje ogłoszenia',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
              child: _userListings.isEmpty
                  ? const Center(
                child: Text(
                  'Brak ogłoszeń',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: _userListings.length,
                itemBuilder: (context, index) {
                  final listing = _userListings[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.directions_car,
                        color: Color(0xFF375534),
                      ),
                      title: Text(
                        listing.brand,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Typ: ${listing.carType}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Status "Oczekujące" lub "Aktualne" na podstawie isApproved
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: listing.isApproved
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.yellow.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              listing.isApproved ? 'Aktualne' : 'Oczekujące',
                              style: TextStyle(
                                fontSize: 14,
                                color: listing.isApproved ? Colors.green : Colors.yellow[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Status "Wypożyczone" jeśli isAvailable jest false
                          if (!listing.isAvailable)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Wypożyczone',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => detailPage.CarListingDetailPage(listing: listing),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}