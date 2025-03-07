import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:provider/provider.dart';
import 'package:test_project/providers/theme_provider.dart';

class MapPicker extends StatefulWidget {
  @override
  _MapPickerState createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  GoogleMapController? _controller;
  LatLng? _selectedLocation;
  TextEditingController _addressController = TextEditingController();
  final GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: 'API_KEY');
  List<Prediction> _placeSuggestions = [];
  bool _isSearching = false;
  String? _mapStyle; // Przechowuje styl mapy

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _loadMapStyle();
  }

  void _onTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  Future<void> _searchAddress(String address) async {
    if (address.isNotEmpty) {
      try {
        setState(() {
          _isSearching = true;
        });
        final placesResponse = await _places.autocomplete(address, components: [Component(Component.country, 'pl')]);
        if (placesResponse.isOkay) {
          setState(() {
            _placeSuggestions = placesResponse.predictions;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Błąd wyszukiwania: ${placesResponse.errorMessage}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd wyszukiwania: $e')),
        );
      } finally {
        setState(() {
          _isSearching = false;
        });
      }
    } else {
      setState(() {
        _placeSuggestions.clear();
      });
    }
  }

  Future<void> _selectSuggestion(Prediction prediction) async {
    try {
      final placeDetails = await _places.getDetailsByPlaceId(prediction.placeId!);
      final location = LatLng(
        placeDetails.result.geometry!.location.lat,
        placeDetails.result.geometry!.location.lng,
      );
      setState(() {
        _selectedLocation = location;
        _placeSuggestions.clear();
        _addressController.text = prediction.description ?? '';
      });
      _controller?.animateCamera(CameraUpdate.newLatLng(location));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd pobierania szczegółów lokalizacji: $e')),
      );
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
    } catch (e) {
      print('Błąd ładowania stylu mapy: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wybierz lokalizację'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _selectedLocation != null
                ? () => Navigator.pop(context, _selectedLocation)
                : null,
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
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: 'Wprowadź adres',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () => _searchAddress(_addressController.text),
                    ),
                  ),
                  onChanged: _searchAddress,
                ),
                if (_isSearching) CircularProgressIndicator(),
                if (_placeSuggestions.isNotEmpty)
                  Container(
                    height: 200,
                    child: ListView.builder(
                      itemCount: _placeSuggestions.length,
                      itemBuilder: (context, index) {
                        final prediction = _placeSuggestions[index];
                        return ListTile(
                          title: Text(prediction.description ?? ''),
                          onTap: () => _selectSuggestion(prediction),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _selectedLocation ?? const LatLng(52.2297, 21.0122),
                zoom: 10,
              ),
              onTap: _onTap,
              markers: _selectedLocation != null
                  ? {
                Marker(
                  markerId: const MarkerId('selected'),
                  position: _selectedLocation!,
                ),
              }
                  : {},
              style: _mapStyle, 
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}