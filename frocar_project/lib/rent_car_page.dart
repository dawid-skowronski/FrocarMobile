import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/api_service.dart';
import '../models/map_point.dart';
import 'package:test_project/widgets/custom_app_bar.dart';

class RentCarPage extends StatefulWidget {
  @override
  _RentCarPageState createState() => _RentCarPageState();
}

class _RentCarPageState extends State<RentCarPage> {
  GoogleMapController? _controller;
  final ApiService _apiService = ApiService();
  final Set<Marker> _markers = {};
  List<MapPoint> _points = [];

  static const LatLng _center = LatLng(52.2296756, 21.0122287); //(Warszawa)

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(title: "FroCar"),
      body: GoogleMap(
        onMapCreated: (controller) => _controller = controller,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 11.0,
        ),
        markers: _markers,
      ),
    );
  }
}
