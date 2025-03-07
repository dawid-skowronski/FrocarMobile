import 'package:flutter/material.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/models/car_listing.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'car_listing_page.dart';
import 'car_listing_detail_page.dart';

class OfferCarPage extends StatefulWidget {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd podczas pobierania ogłoszeń: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Zarządzaj ogłoszeniami"),
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
                  MaterialPageRoute(builder: (context) => CarListingPage()),
                ).then((_) => _loadUserListings());
              },
              child: Card(
                color: Color(0xFF375534),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 32),
                      SizedBox(width: 8),
                      Text('Dodaj nowe ogłoszenie', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Panel "Moje ogłoszenia"
            Text('Moje ogłoszenia', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Expanded(
              child: _userListings.isEmpty
                  ? Center(child: Text('Brak ogłoszeń'))
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
                          builder: (context) => CarListingDetailPage(listing: listing),
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