import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../models/car_listing.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'car_listing_detail_page.dart';

class RentCarPage extends StatefulWidget {
  @override
  _RentCarPageState createState() => _RentCarPageState();
}

class _RentCarPageState extends State<RentCarPage> {
  GoogleMapController? _controller;
  final ApiService _apiService = ApiService();
  final Set<Marker> _markers = {};
  List<CarListing> _carListings = [];
  static const LatLng _center = LatLng(52.2296756, 21.0122287); // Warszawa
  double _currentZoom = 11.0; 
  static const double _zoomThreshold = 14.0; // Próg zoomu przy którym pokazują się nazwy aut

  @override
  void initState() {
    super.initState();
    _loadCarListings();
  }

  Future<void> _loadCarListings() async {
    try {
      final carListings = await _apiService.getCarListings();
      setState(() {
        _carListings = carListings;
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
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
            markers: _markers,
            onCameraMove: _onCameraMove,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}