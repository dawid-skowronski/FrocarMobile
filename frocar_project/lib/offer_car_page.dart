import 'dart:async';

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/car_listing.dart';
import '../widgets/custom_app_bar.dart';
import 'car_listing_page.dart' as listingPage;
import 'car_listing_detail_page.dart' as detailPage;

class OfferCarPage extends StatefulWidget {
  final ApiService apiService;

  OfferCarPage({
    Key? key,
    ApiService? apiService,
  })  : apiService = apiService ?? ApiService(),
        super(key: key);

  @override
  _OfferCarPageState createState() => _OfferCarPageState();
}

class _OfferCarPageState extends State<OfferCarPage> {
  List<CarListing> _userListings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserListings();
    });
  }

  Future<void> _loadUserListings() async {
    try {
      final listings = await widget.apiService.getUserCarListings();
      setState(() {
        _userListings = listings;
        _isLoading = false;
      });
    } catch (e) {
      final errorMsg = _mapErrorMessage(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _userListings = [];
        _isLoading = false;
      });
    }
  }

  String _mapErrorMessage(String raw) {
    final message = raw.replaceFirst('Exception: ', '');
    if (message.contains('timeout')) {
      return 'Błąd połączenia z serwerem. Spróbuj ponownie później.';
    } else if (message.contains('401')) {
      return 'Nieautoryzowany dostęp. Zaloguj się ponownie.';
    } else {
      return 'Wystąpił problem podczas pobierania ogłoszeń.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Zarządzaj ogłoszeniami",
        onNotificationPressed: () {
          Navigator.pushNamed(context, '/notifications');
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const listingPage.CarListingPage(),
                  ),
                ).then((_) => _loadUserListings());
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
            const Text(
              'Moje ogłoszenia',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _isLoading
                ? const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
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
                          if (!listing.isAvailable)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
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
                            builder: (_) => detailPage.CarListingDetailPage(
                              listing: listing,
                            ),
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
