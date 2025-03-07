import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart'; // Potrzebne do wczytania stylów mapy
import '../services/api_service.dart';
import '../models/map_point.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart'; // Import ThemeProvider

class RentCarPage extends StatefulWidget {
  @override
  _RentCarPageState createState() => _RentCarPageState();
}

class _RentCarPageState extends State<RentCarPage> {
  GoogleMapController? _controller;
  final ApiService _apiService = ApiService();
  final Set<Marker> _markers = {};
  List<MapPoint> _points = [];
  final int _userId = 1; // Przykładowe ID użytkownika
  static const LatLng _center = LatLng(52.2296756, 21.0122287); // Warszawa

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    try {
      final points = await _apiService.getPoints();
      setState(() {
        _points = points;
        _markers.clear();
        _markers.addAll(_points.map((point) => Marker(
          markerId: MarkerId(point.id.toString()),
          position: LatLng(point.latitude, point.longitude),
          infoWindow: InfoWindow(title: 'Punkt ${point.id}'),
        )));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd podczas pobierania punktów: $e')),
      );
    }
  }

  /// Funkcja zmienia styl mapy w zależności od motywu aplikacji
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

  void _addMarker(LatLng position) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Dodaj punkt'),
          content: Text('Czy na pewno chcesz dodać punkt w tym miejscu?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Anuluj'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final markerId = _markers.length + 1;
                final marker = Marker(
                  markerId: MarkerId(markerId.toString()),
                  position: position,
                  infoWindow: InfoWindow(title: 'Punkt $markerId'),
                );

                setState(() {
                  _markers.add(marker);
                });

                final point = MapPoint(
                  latitude: position.latitude,
                  longitude: position.longitude,
                  userId: _userId,
                );

                try {
                  await _apiService.addPoint(point);
                  await _loadPoints();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Punkt dodany pomyślnie!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Błąd podczas dodawania punktu: $e')),
                  );
                }
              },
              child: Text('Dodaj'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(title: "FroCar"),
      body: Stack(
        children: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              _setMapStyle(); // Ustawienie stylu mapy na podstawie motywu
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
                onTap: (position) {
                  _addMarker(position);
                },
              );
            },
          ),
          Positioned(
            bottom: 16.0,
            left: 16.0,
            child: FloatingActionButton(
              onPressed: () {
                _addMarker(_center);
              },
              child: Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
