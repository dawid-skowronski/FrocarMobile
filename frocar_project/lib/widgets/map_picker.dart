import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:test_project/providers/theme_provider.dart';
import 'package:geolocator/geolocator.dart';

class SelectedLocation {
  final double latitude;
  final double longitude;

  SelectedLocation({required this.latitude, required this.longitude});
}

class MapPicker extends StatefulWidget {
  final http.Client? httpClient;

  const MapPicker({Key? key, this.httpClient}) : super(key: key);

  @override
  _MapPickerState createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  GoogleMapController? _controller;
  LatLng? _selectedLocation;
  final addressController = TextEditingController();
  bool _isSearching = false;
  String? _mapStyle;
  late http.Client client;
  LatLng _initialPosition = const LatLng(52.2297, 21.0122); // Domyślnie Warszawa

  @override
  void initState() {
    super.initState();
    client = widget.httpClient ?? http.Client();
    _getCurrentLocation(); // Pobierz lokalizację użytkownika
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Sprawdź, czy usługi lokalizacji są włączone
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Usługi lokalizacji są wyłączone.');
        return;
      }

      // Sprawdź pozwolenia
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Pozwolenie na lokalizację odrzucone.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Pozwolenie na lokalizację permanentnie odrzucone.');
        return;
      }

      // Pobierz bieżącą lokalizację
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
        _selectedLocation = _initialPosition; // Ustaw domyślnie wybraną lokalizację
      });

      // Przesuń kamerę na bieżącą lokalizację
      if (_controller != null) {
        _controller!.animateCamera(
          CameraUpdate.newLatLng(_initialPosition),
        );
      }
    } catch (e) {
      print('Błąd pobierania lokalizacji: $e');
      // Użyj domyślnej pozycji (Warszawa) w przypadku błędu
    }
  }

  void _onMapCreated(GoogleMapController controller) async {
    _controller = controller;
    await _loadMapStyle();
    // Przesuń kamerę na początkową pozycję (lokalizacja użytkownika lub Warszawa)
    _controller!.animateCamera(
      CameraUpdate.newLatLng(_initialPosition),
    );
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
      final response = await client.get(
        url,
        headers: {
          'User-Agent': 'FrogCarApp/1.0 (jakub.trznadel@studenci.collegiumwitelona.pl)',
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
      _controller?.setMapStyle(style);
    } catch (_) {}
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
            onPressed: _confirmSelection,
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
              initialCameraPosition: CameraPosition(
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
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    addressController.dispose();
    client.close();
    super.dispose();
  }
}