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
        // Filtrujemy listę: tylko auta, których użytkownik nie jest właścicielem i które są dostępne
        _carListings = carListings.where((listing) {
          return listing.userId != _currentUserId && listing.isAvailable;
        }).toList();
        print('Filtered car listings: ${_carListings.length}');
        _updateMarkers();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd podczas pobierania ogłoszeń: $e')),
      );
    }
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

  void _showRentedCarsBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return FutureBuilder<List<CarRental>>(
          future: _apiService.getUserCarRentals(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              // W przypadku błędu wyświetlamy prosty komunikat zamiast szczegółów błędu
              return const Center(
                child: Text(
                  'Brak aktualnie wypożyczonych aut',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'Brak aktualnie wypożyczonych aut',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              );
            } else {
              final rentals = snapshot.data!;
              return ListView.builder(
                itemCount: rentals.length,
                itemBuilder: (context, index) {
                  final rental = rentals[index];
                  return ListTile(
                    title: Text(rental.carListing.brand),
                    subtitle: Text(
                      'Od: ${rental.rentalStartDate.toString().substring(0, 10)} Do: ${rental.rentalEndDate.toString().substring(0, 10)}',
                    ),
                    trailing: Text(rental.rentalStatus),
                  );
                },
              );
            }
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