import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SelectedLocation {
  final double latitude;
  final double longitude;

  SelectedLocation({required this.latitude, required this.longitude});
}

class MapPicker extends StatefulWidget {
  const MapPicker({super.key});

  @override
  _MapPickerState createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  GoogleMapController? _controller;
  LatLng? _selectedLocation;
  final addressController = TextEditingController();
  bool _isSearching = false;
  String? _mapStyle; // Przechowuje styl mapy

  static const LatLng _initialPosition = LatLng(52.2297, 21.0122); // Domyślna pozycja (Warszawa)

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _loadMapStyle();
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
  }

  Future<void> _searchAddress() async {
    final address = addressController.text;
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proszę wpisać adres'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeQueryComponent(address)}&format=json&limit=1');
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'FrogCarApp/1.0 (twoj.email@example.com)', // Zmień na unikalny User-Agent
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final position = LatLng(lat, lon);
          setState(() {
            _selectedLocation = position;
          });
          _controller?.animateCamera(CameraUpdate.newLatLng(position));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nie znaleziono lokalizacji dla podanego adresu'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else {
        throw Exception('Błąd podczas geokodowania: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd podczas wyszukiwania adresu: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _loadMapStyle() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final stylePath = themeProvider.isDarkMode
        ? 'assets/map_styles/dark_mode.json'
        : 'assets/map_styles/light_mode.json';

    try {
      String style = await DefaultAssetBundle.of(context).loadString(stylePath);
      setState(() {
        _mapStyle = style;
      });
      _controller?.setMapStyle(style); // Ustawienie stylu po załadowaniu
    } catch (e) {
      print('Błąd ładowania stylu mapy: $e');
    }
  }

  void _confirmSelection() {
    if (_selectedLocation != null) {
      Navigator.pop(
        context,
        SelectedLocation(
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proszę wybrać lokalizację na mapie'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wybierz lokalizację'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _selectedLocation != null ? _confirmSelection : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    hintText: 'Wprowadź adres',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _searchAddress,
                    ),
                  ),
                ),
                if (_isSearching) const CircularProgressIndicator(),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: _initialPosition,
                zoom: 10,
              ),
              onTap: _onMapTapped,
              markers: _selectedLocation != null
                  ? {
                Marker(
                  markerId: const MarkerId('selected-location'),
                  position: _selectedLocation!,
                ),
              }
                  : {},
              style: _mapStyle, // Użycie stylu mapy
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }
}