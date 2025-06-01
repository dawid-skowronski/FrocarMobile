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
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../models/car_rental_review.dart';
import 'add_review_page.dart';

class RentCarPage extends StatefulWidget {
  const RentCarPage({super.key});

  @override
  _RentCarPageState createState() => _RentCarPageState();
}

class _RentCarPageState extends State<RentCarPage> {
  GoogleMapController? _controller;
  final Set<Marker> _markers = {};
  List<CarListing> _carListings = [];
  List<CarRental> _userRentals = [];
  static const LatLng _center = LatLng(52.2296756, 21.0122287);
  double _currentZoom = 11.0;
  static const double _zoomThreshold = 14.0;
  int? _currentUserId;
  bool _isShowingInfoWindows = false;

  String? _filterBrand;
  int? _minSeats;
  int? _maxSeats;
  List<String> _filterFuelTypes = [];
  double? _minPrice;
  double? _maxPrice;
  List<String> _filterCarTypes = [];
  String? _filterCity;
  double? _filterRadius;
  LatLng? _filterCityCoordinates;

  final List<String> _availableFuelTypes = ['Benzyna', 'Diesel', 'Elektryczny', 'Hybryda', 'LPG'];
  final List<String> _availableCarTypes = [
    'SUV', 'Sedan', 'Kombi', 'Hatchback', 'Coupe', 'Cabrio', 'Pickup', 'Van',
    'Minivan', 'Crossover', 'Limuzyna', 'Microcar', 'Roadster', 'Muscle car',
    'Terenowy', 'Targa'
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId().then((_) {
      _loadCarListings();
      _loadUserRentals();
    });
  }

  Future<void> _loadCurrentUserId() async {
    final storage = Provider.of<FlutterSecureStorage>(context, listen: false);
    final token = await storage.read(key: 'token');
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length != 3) {
          throw Exception('Nieprawidłowy token JWT');
        }
        final payload = parts[1];
        final decodedPayload = utf8.decode(base64.decode(base64.normalize(payload)));
        final decoded = jsonDecode(decodedPayload) as Map<String, dynamic>;
        _currentUserId = int.parse(
            decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ?? '0');
      } catch (e) {
        print('Błąd ładowania ID użytkownika: $e');
        _currentUserId = null;
      }
    } else {
      _currentUserId = null;
    }
  }

  Future<void> _loadCarListings() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final carListings = await apiService.getCarListings();
      setState(() {
        _carListings = carListings.where((listing) {
          bool matches = listing.userId != _currentUserId && listing.isAvailable;

          if (_filterBrand != null && _filterBrand!.isNotEmpty) {
            matches = matches && listing.brand.toLowerCase().contains(_filterBrand!.toLowerCase());
          }

          if (_minSeats != null) {
            matches = matches && listing.seats >= _minSeats!;
          }
          if (_maxSeats != null) {
            matches = matches && listing.seats <= _maxSeats!;
          }

          if (_filterFuelTypes.isNotEmpty) {
            matches = matches && _filterFuelTypes.contains(listing.fuelType);
          }

          if (_minPrice != null) {
            matches = matches && listing.rentalPricePerDay >= _minPrice!;
          }
          if (_maxPrice != null) {
            matches = matches && listing.rentalPricePerDay <= _maxPrice!;
          }

          if (_filterCarTypes.isNotEmpty) {
            matches = matches && _filterCarTypes.contains(listing.carType);
          }

          if (_filterCityCoordinates != null && _filterRadius != null) {
            final distance = Geolocator.distanceBetween(
              _filterCityCoordinates!.latitude,
              _filterCityCoordinates!.longitude,
              listing.latitude,
              listing.longitude,
            ) / 1000;
            matches = matches && distance <= _filterRadius!;
          }

          return matches;
        }).toList();
        print('Załadowano ${_carListings.length} listingów');
        if (_carListings.isEmpty) {
          _showErrorDialog('Brak dostępnych aut spełniających kryteria');
        } else {
          _updateMarkers();
        }
      });
    } catch (e) {
      _showErrorDialog('Brak dostępnych aut do wypożyczenia: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> _loadUserRentals() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final rentals = await apiService.getUserCarRentals();
      setState(() {
        _userRentals = rentals;
        print('Załadowano ${_userRentals.length} wypożyczeń');
      });
    } catch (e) {
      print('Błąd ładowania wypożyczeń: $e');
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

  void _updateMarkers() async {
    final BitmapDescriptor carIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/car_icon.png',
    );

    _markers.clear();
    for (var listing in _carListings) {
      print('Dodaję marker dla ${listing.brand}, ID: ${listing.id}, współrzędne: (${listing.latitude}, ${listing.longitude})');

      if (listing.latitude.isNaN || listing.longitude.isNaN) {
        print('Błąd: Nieprawidłowe współrzędne dla markera ${listing.id}');
        continue;
      }

      _markers.add(Marker(
        markerId: MarkerId(listing.id.toString()),
        position: LatLng(listing.latitude, listing.longitude),
        icon: carIcon,
        consumeTapEvents: true,
        infoWindow: InfoWindow(
          title: listing.brand.isNotEmpty ? listing.brand : 'Brak marki',
          snippet: 'Cena: ${listing.rentalPricePerDay.toStringAsFixed(2)} PLN/dzień',
        ),
        onTap: () {
          print('Przekierowuję do szczegółów listingu ${listing.id}');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CarListingDetailPage(listing: listing),
            ),
          );
        },
      ));
    }

    setState(() {
      print('Zaktualizowano markery, liczba markerów: ${_markers.length}');
    });
  }

  Future<void> _setMapStyle() async {
    if (_controller == null) return;

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final stylePath = themeProvider.isDarkMode
        ? 'assets/map_styles/dark_mode.json'
        : 'assets/map_styles/light_mode.json';

    try {
      String style = await rootBundle.loadString(stylePath);
      _controller!.setMapStyle(style);
    } catch (e) {
      print('Błąd ładowania stylu mapy: $e');
    }
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _currentZoom = position.zoom;
      print('Zmiana zoomu: $_currentZoom');
    });

    bool shouldShowInfoWindows = _currentZoom >= _zoomThreshold;
    if (shouldShowInfoWindows && !_isShowingInfoWindows) {
      _showAllInfoWindows();
      _isShowingInfoWindows = true;
    } else if (!shouldShowInfoWindows && _isShowingInfoWindows) {
      _hideAllInfoWindows();
      _isShowingInfoWindows = false;
    }
  }

  Future<void> _showAllInfoWindows() async {
    if (_controller == null) return;

    final bounds = await _controller!.getVisibleRegion();
    print('Widoczny obszar mapy: $bounds');

    Future.delayed(const Duration(milliseconds: 500), () {
      for (var marker in _markers) {
        bool isVisible = bounds.contains(marker.position);
        if (isVisible) {
          _controller!.showMarkerInfoWindow(marker.markerId);
          print('Pokazuję InfoWindow dla markera ${marker.markerId} na pozycji ${marker.position}');
        } else {
          _controller!.hideMarkerInfoWindow(marker.markerId);
          print('Ukrywam InfoWindow dla markera ${marker.markerId}, bo jest poza widocznym obszarem');
        }
      }
    });
  }

  void _hideAllInfoWindows() {
    if (_controller == null) return;
    for (var marker in _markers) {
      _controller!.hideMarkerInfoWindow(marker.markerId);
      print('Ukrywam InfoWindow dla markera ${marker.markerId}');
    }
  }

  double _calculateTotalPrice(CarRental rental) {
    final days = rental.rentalEndDate.difference(rental.rentalStartDate).inDays;
    return days * rental.carListing.rentalPricePerDay;
  }

  int _calculateDaysUntilEnd(CarRental rental) {
    final now = DateTime.now();
    if (rental.rentalEndDate.isBefore(now)) {
      return 0;
    }
    return rental.rentalEndDate.difference(now).inDays;
  }

  void _showRentedCarsBottomSheet() {
    bool showEndedRentals = false;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final filteredRentals = _userRentals.where((rental) {
              print('Filtruję rental: ${rental.rentalStatus}, showEndedRentals: $showEndedRentals');
              return showEndedRentals || rental.rentalStatus != 'Zakończone';
            }).toList();

            return Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pokaż zakończone wypożyczenia',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Switch(
                          value: showEndedRentals,
                          onChanged: (value) {
                            setModalState(() {
                              showEndedRentals = value;
                            });
                          },
                          activeColor: const Color(0xFF375534),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filteredRentals.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.directions_car,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            showEndedRentals
                                ? 'Brak zakończonych wypożyczeń'
                                : 'Brak aktualnie wypożyczonych aut',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      itemCount: filteredRentals.length,
                      itemBuilder: (context, index) {
                        final rental = filteredRentals[index];
                        return FutureBuilder<List<CarRentalReview>>(
                          future: Provider.of<ApiService>(context, listen: false)
                              .getReviewsForListing(rental.carListingId),
                          builder: (context, reviewSnapshot) {
                            bool canAddReview = false;
                            if (reviewSnapshot.hasData) {
                              final reviews = reviewSnapshot.data!;
                              canAddReview = !reviews.any(
                                      (review) => review.carRentalId == rental.carRentalId);
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ExpansionTile(
                                key: Key(index.toString()),
                                initiallyExpanded: false,
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: rental.rentalStatus == 'Aktywne'
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    rental.rentalStatus,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: rental.rentalStatus == 'Aktywne'
                                          ? Colors.green
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 8.0),
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
                                        if (rental.rentalStatus == 'Zakończone' && canAddReview) ...[
                                          const SizedBox(height: 16),
                                          Center(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => AddReviewPage(
                                                      carRentalId: rental.carRentalId,
                                                      carListingId: rental.carListingId,
                                                    ),
                                                  ),
                                                ).then((_) {
                                                  _loadUserRentals();
                                                  setModalState(() {});
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF375534),
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 32, vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: const Text(
                                                'Dodaj opinię',
                                                style: TextStyle(fontSize: 16, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterBottomSheet() {
    final brandController = TextEditingController(text: _filterBrand ?? '');
    final minSeatsController = TextEditingController(text: _minSeats?.toString() ?? '');
    final maxSeatsController = TextEditingController(text: _maxSeats?.toString() ?? '');
    final minPriceController = TextEditingController(text: _minPrice?.toString() ?? '');
    final maxPriceController = TextEditingController(text: _maxPrice?.toString() ?? '');
    final cityController = TextEditingController(text: _filterCity ?? '');
    final radiusController = TextEditingController(text: _filterRadius?.toString() ?? '');

    List<String> tempFuelTypes = List.from(_filterFuelTypes);
    List<String> tempCarTypes = List.from(_filterCarTypes);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtry wyszukiwania',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF375534),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: brandController,
                      decoration: const InputDecoration(
                        labelText: 'Marka',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minSeatsController,
                            decoration: const InputDecoration(
                              labelText: 'Min. miejsc',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: maxSeatsController,
                            decoration: const InputDecoration(
                              labelText: 'Maks. miejsc',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Typ paliwa',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Wrap(
                      spacing: 8,
                      children: _availableFuelTypes.map((fuelType) {
                        return FilterChip(
                          label: Text(fuelType),
                          selected: tempFuelTypes.contains(fuelType),
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                tempFuelTypes.add(fuelType);
                              } else {
                                tempFuelTypes.remove(fuelType);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Min. cena (PLN)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: maxPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Maks. cena (PLN)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Typ samochodu',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Wrap(
                      spacing: 8,
                      children: _availableCarTypes.map((carType) {
                        return FilterChip(
                          label: Text(carType),
                          selected: tempCarTypes.contains(carType),
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                tempCarTypes.add(carType);
                              } else {
                                tempCarTypes.remove(carType);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Lokalizacja',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: cityController,
                      decoration: const InputDecoration(
                        labelText: 'Miasto (np. Warszawa)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: radiusController,
                      decoration: const InputDecoration(
                        labelText: 'Promień (km)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Anuluj',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  brandController.clear();
                                  minSeatsController.clear();
                                  maxSeatsController.clear();
                                  minPriceController.clear();
                                  maxPriceController.clear();
                                  cityController.clear();
                                  radiusController.clear();
                                  tempFuelTypes.clear();
                                  tempCarTypes.clear();
                                });
                              },
                              child: const Text(
                                'Wyczyść',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                LatLng? cityCoordinates;
                                if (cityController.text.isNotEmpty) {
                                  try {
                                    final locations = await locationFromAddress(cityController.text);
                                    if (locations.isNotEmpty) {
                                      final location = locations.first;
                                      cityCoordinates = LatLng(location.latitude, location.longitude);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Nie znaleziono podanego miasta.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Błąd podczas wyszukiwania miasta: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                }

                                setState(() {
                                  _filterBrand = brandController.text.isEmpty ? null : brandController.text;
                                  _minSeats = minSeatsController.text.isEmpty
                                      ? null
                                      : int.tryParse(minSeatsController.text);
                                  _maxSeats = maxSeatsController.text.isEmpty
                                      ? null
                                      : int.tryParse(maxSeatsController.text);
                                  _filterFuelTypes = tempFuelTypes;
                                  _minPrice = minPriceController.text.isEmpty
                                      ? null
                                      : double.tryParse(minPriceController.text);
                                  _maxPrice = maxPriceController.text.isEmpty
                                      ? null
                                      : double.tryParse(maxPriceController.text);
                                  _filterCarTypes = tempCarTypes;
                                  _filterCity = cityController.text.isEmpty ? null : cityController.text;
                                  _filterRadius = radiusController.text.isEmpty
                                      ? null
                                      : double.tryParse(radiusController.text);
                                  _filterCityCoordinates = cityCoordinates;
                                  _loadCarListings();
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF375534),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Zastosuj'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
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
      appBar: CustomAppBar(
        title: "Wypożycz auto",
        onNotificationPressed: () {
          Navigator.pushNamed(context, '/notifications');
        },
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          _setMapStyle();
          return GoogleMap(
            onMapCreated: (controller) {
              print('Mapa utworzona, controller: $controller');
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _showFilterBottomSheet,
            backgroundColor: const Color(0xFF375534),
            child: const Icon(Icons.filter_list, color: Colors.white),
            heroTag: 'filterButton',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _showRentedCarsBottomSheet,
            backgroundColor: const Color(0xFF375534),
            child: const Icon(Icons.car_rental, color: Colors.white),
            heroTag: 'rentedCarsButton',
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}