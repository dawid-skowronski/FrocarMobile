import 'package:flutter/material.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/models/car_listing.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'car_listing_page.dart' as listingPage; 
import 'car_listing_detail_page.dart' as detailPage; 
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
      // Zamiast pokazywać SnackBar, ustawiamy pustą listę i kończymy ładowanie
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
                  return ListTile(
                    title: Text(listing.brand),
                    subtitle: Text('Typ: ${listing.carType}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => detailPage.CarListingDetailPage(listing: listing),
                        ),
                      );
                    },
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