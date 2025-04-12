import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:test_project/services/api_service.dart';
import '../models/car_listing.dart';
import '../models/car_rental.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'car_listing_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RentCarPage extends StatefulWidget {
  @override
  _RentCarPageState createState() => _RentCarPageState();
}

class _RentCarPageState extends State<RentCarPage> {
  GoogleMapController? _controller;
  final ApiService _apiService = ApiService();
  final Set<Marker> _markers = {};
  List<CarListing> _carListings = [];
  static const LatLng _center = LatLng(52.2296756, 21.0122287);
  double _currentZoom = 11.0;
  static const double _zoomThreshold = 14.0;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId().then((_) {
      _loadCarListings();
    });
  }

  // Funkcja do pobierania ID aktualnego użytkownika z tokenu JWT
  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      print('Token from SharedPreferences: $token');
      try {
        final parts = token.split('.');
        if (parts.length != 3) {
          throw Exception('Nieprawidłowy token JWT');
        }
        final payload = parts[1];
        final decodedPayload = utf8.decode(base64.decode(base64.normalize(payload)));
        final decoded = jsonDecode(decodedPayload) as Map<String, dynamic>;
        print('Decoded token: $decoded');
        _currentUserId = int.parse(
            decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ?? '0');
        print('Current User ID: $_currentUserId');
      } catch (e) {
        print('Błąd dekodowania tokenu: $e');
        _currentUserId = null;
      }
    } else {
      print('Brak tokenu w SharedPreferences');
      _currentUserId = null;
    }
  }

  Future<void> _loadCarListings() async {
    try {
      final carListings = await _apiService.getCarListings();
      setState(() {
        _carListings = carListings.where((listing) {
          return listing.userId != _currentUserId && listing.isAvailable;
        }).toList();
        print('Filtered car listings: ${_carListings.length}');
        if (_carListings.isEmpty) {
          _showErrorDialog('Brak dostępnych aut do wypożyczenia');
        } else {
          _updateMarkers();
        }
      });
    } catch (e) {
      _showErrorDialog('Brak dostępnych aut do wypożyczenia');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Icon(
            Icons.directions_car,
            size: 48,
            color: Colors.grey,
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF375534),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateMarkers() {
    _markers.clear();
    _markers.addAll(_carListings.map((listing) => Marker(
      markerId: MarkerId(listing.id.toString()),
      position: LatLng(listing.latitude, listing.longitude),
      infoWindow: InfoWindow(
        title: listing.brand,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CarListingDetailPage(listing: listing),
          ),
        );
      },
    )));
    if (_currentZoom >= _zoomThreshold) {
      _showAllInfoWindows();
    }
  }

  Future<void> _setMapStyle() async {
    if (_controller == null) return;

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final stylePath = themeProvider.isDarkMode
        ? 'assets/map_styles/dark_mode.json'
        : 'assets/map_styles/light_mode.json';

    try {
      String style = await rootBundle.loadString(stylePath);
      _controller?.setMapStyle(style);
    } catch (e) {
      print('Błąd ładowania stylu mapy: $e');
    }
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _currentZoom = position.zoom;
    });
    if (_currentZoom >= _zoomThreshold) {
      _showAllInfoWindows();
    } else {
      _hideAllInfoWindows();
    }
  }

  void _showAllInfoWindows() {
    for (var marker in _markers) {
      _controller?.showMarkerInfoWindow(marker.markerId);
    }
  }

  void _hideAllInfoWindows() {
    for (var marker in _markers) {
      _controller?.hideMarkerInfoWindow(marker.markerId);
    }
  }

  // Funkcja obliczająca całkowitą cenę wypożyczenia
  double _calculateTotalPrice(CarRental rental) {
    final days = rental.rentalEndDate.difference(rental.rentalStartDate).inDays;
    return days * rental.carListing.rentalPricePerDay;
  }

  // Funkcja obliczająca dni do końca wypożyczenia
  int _calculateDaysUntilEnd(CarRental rental) {
    final now = DateTime.now();
    if (rental.rentalEndDate.isBefore(now)) {
      return 0; // Wypożyczenie już się zakończyło
    }
    return rental.rentalEndDate.difference(now).inDays;
  }

  void _showRentedCarsBottomSheet() {
    // Zmienna do śledzenia, który element jest rozwinięty
    int? expandedIndex;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return FutureBuilder<List<CarRental>>(
              future: _apiService.getUserCarRentals(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.directions_car,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Brak aktualnie wypożyczonych aut',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                } else {
                  final rentals = snapshot.data!;
                  return Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ListView.builder(
                      itemCount: rentals.length,
                      itemBuilder: (context, index) {
                        final rental = rentals[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ExpansionTile(
                            key: Key(index.toString()),
                            initiallyExpanded: expandedIndex == index,
                            onExpansionChanged: (bool expanded) {
                              setModalState(() {
                                if (expanded) {
                                  expandedIndex = index;
                                } else {
                                  expandedIndex = null;
                                }
                              });
                            },
                            leading: const Icon(
                              Icons.directions_car,
                              color: Color(0xFF375534),
                            ),
                            title: Text(
                              rental.carListing.brand,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Od: ${rental.rentalStartDate.toString().substring(0, 10)} Do: ${rental.rentalEndDate.toString().substring(0, 10)}',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: rental.rentalStatus == 'Active'
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                rental.rentalStatus,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: rental.rentalStatus == 'Active' ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.monetization_on,
                                          color: Color(0xFF375534),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Cena wypożyczenia: ${_calculateTotalPrice(rental).toStringAsFixed(2)} PLN',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.timer,
                                          color: Color(0xFF375534),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Dni do końca wypożyczenia: ${_calculateDaysUntilEnd(rental)}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey,
                                            ),
                                          ),
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
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(title: "Wypożycz auto"),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          _setMapStyle();
          return GoogleMap(
            onMapCreated: (controller) {
              _controller = controller;
              _setMapStyle();
            },
            initialCameraPosition: const CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
            markers: _markers,
            onCameraMove: _onCameraMove,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showRentedCarsBottomSheet,
        backgroundColor: const Color(0xFF375534),
        child: const Icon(Icons.car_rental, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}