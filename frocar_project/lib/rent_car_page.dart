import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/models/car_listing.dart';
import 'package:test_project/models/car_rental.dart';
import 'package:test_project/models/car_rental_review.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:test_project/filters/filter_strategy.dart';
import 'package:test_project/add_review_page.dart';
import 'package:test_project/car_listing_detail_page.dart';

const String _appBarTitle = "Wypożycz auto";
const String _rentedCarsButtonText = "Moje wypożyczenia";
const String _filterButtonText = "Filtry";
const String _locationServiceDisabled = 'Usługi lokalizacji są wyłączone.';
const String _locationPermissionDenied = 'Pozwolenie na lokalizację odrzucone.';
const String _locationPermissionDeniedForever = 'Pozwolenie na lokalizację permanentnie odrzucone.';
const String _locationFetchError = 'Błąd pobierania lokalizacji:';
const String _jwtTokenError = 'Nieprawidłowy token JWT';
const String _userIdLoadError = 'Błąd ładowania ID użytkownika:';
const String _listingsLoadError = 'Nie można załadować ogłoszeń.';
const String _noInternetError = 'Brak połączenia z internetem.';
const String _noListingsMatchingCriteria = 'Brak dostępnych aut spełniających kryteria';
const String _rentalsLoadError = 'Błąd ładowania wypożyczeń:';
const String _mapStyleLoadError = 'Błąd ładowania stylu mapy:';
const String _okButtonText = 'OK';

const String _showEndedRentalsSwitchText = 'Pokaż zakończone wypożyczenia';
const String _noEndedOrCanceledRentals = 'Brak zakończonych lub anulowanych wypożyczeń';
const String _noActiveRentals = 'Brak aktywnych wypożyczeń';
const String _rentalDatesLabel = 'Od: %s Do: %s';
const String _rentalPriceLabel = 'Cena wypożyczenia: %s PLN';
const String _daysRemainingLabel = 'Dni do końca wypożyczenia: %s';
const String _addReviewButtonText = 'Dodaj opinię';
const String _rentalStatusActive = 'Aktywne';
const String _rentalStatusEnded = 'Zakończone';
const String _rentalStatusCanceled = 'Anulowane';

const String _cancelRentalButtonText = 'Anuluj wypożyczenie';
const String _cancelRentalConfirmTitle = 'Anuluj wypożyczenie';
const String _cancelRentalConfirmMessage = 'Czy na pewno chcesz anulować to wypożyczenie?';
const String _yesButtonText = 'Tak';
const String _noButtonText = 'Nie';
const String _cancelSuccess = 'Wypożyczenie anulowane pomyślnie!';
const String _cancelError = 'Błąd podczas anulowania wypożyczenia:';

const String _filterTitle = 'Filtry wyszukiwania';
const String _brandFilterLabel = 'Marka';
const String _minSeatsLabel = 'Min. miejsc';
const String _maxSeatsLabel = 'Maks. miejsc';
const String _fuelTypeLabel = 'Typ paliwa';
const String _minPriceLabel = 'Min. cena (PLN)';
const String _maxPriceLabel = 'Maks. cena (PLN)';
const String _carTypeLabel = 'Typ samochodu';
const String _locationLabel = 'Lokalizacja';
const String _cityHint = 'Miasto (np. Warszawa)';
const String _radiusLabel = 'Promień (km)';
const String _cancelButtonText = 'Anuluj';
const String _applyFiltersButtonText = 'Zastosuj';
const String _clearFiltersButtonText = 'Wyczyść';
const String _geocodingError = 'Błąd podczas wyszukiwania miasta:';
const String _cityNotFound = 'Nie znaleziono podanego miasta.';
const String _searchingLocationText = 'Szukam lokalizacji...';

const Color _themeColor = Color(0xFF375534);
const Color _amberColor = Colors.amber;
const Color _redColor = Colors.red;
const Color _greenColor = Colors.green;
const Color _greyColor = Colors.grey;

class RentCarPage extends StatefulWidget {
  const RentCarPage({super.key});

  @override
  _RentCarPageState createState() => _RentCarPageState();
}

class _RentCarPageState extends State<RentCarPage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  List<CarListing> _carListings = [];
  List<CarRental> _userRentals = [];
  LatLng _center = const LatLng(52.2296756, 21.0122287);
  double _currentZoom = 11.0;
  static const double _zoomThreshold = 14.0;
  int? _currentUserId;
  bool _isShowingInfoWindows = false;
  bool _showEndedRentals = false;

  bool _isLocationLoading = false;
  bool _isListingsLoading = false;
  bool _isRentalsLoading = false;

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
  List<FilterStrategy> _filterStrategies = [];

  final List<String> _availableFuelTypes = [
    'Benzyna',
    'Diesel',
    'Elektryczny',
    'Hybryda',
    'LPG'
  ];
  final List<String> _availableCarTypes = [
    'SUV',
    'Sedan',
    'Kombi',
    'Hatchback',
    'Coupe',
    'Cabrio',
    'Pickup',
    'Van',
    'Minivan',
    'Crossover',
    'Limuzyna',
    'Microcar',
    'Roadster',
    'Muscle car',
    'Terenowy',
    'Targa'
  ];

  ThemeMode? _currentThemeMode;

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initializePageData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final themeProvider = Provider.of<ThemeProvider>(context);
    if (_currentThemeMode == null || _currentThemeMode != themeProvider.themeMode) {
      _currentThemeMode = themeProvider.themeMode;
      _setMapStyle();
    }
  }

  Future<void> _initializePageData() async {
    setState(() {
      _isLocationLoading = true;
      _isListingsLoading = true;
      _isRentalsLoading = true;
    });

    try {
      await _getCurrentLocation();
    } finally {
      setState(() {
        _isLocationLoading = false;
      });
    }

    await _loadCurrentUserId();
    _updateFilterStrategies();

    try {
      await _loadCarListings();
    } finally {
      setState(() {
        _isListingsLoading = false;
      });
    }

    try {
      await _loadUserRentals();
    } finally {
      setState(() {
        _isRentalsLoading = false;
      });
    }
  }

  void _updateFilterStrategies() {
    setState(() {
      _filterStrategies = [
        UserAndAvailabilityFilterStrategy(_currentUserId),
        BrandFilterStrategy(_filterBrand),
        SeatsFilterStrategy(_minSeats, _maxSeats),
        FuelTypeFilterStrategy(_filterFuelTypes),
        PriceFilterStrategy(_minPrice, _maxPrice),
        CarTypeFilterStrategy(_filterCarTypes),
        LocationFilterStrategy(_filterCityCoordinates, _filterRadius),
      ];
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint(_locationServiceDisabled);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint(_locationPermissionDenied);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(_locationPermissionDeniedForever);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _center = LatLng(position.latitude, position.longitude);
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(_center),
        );
      }
    } catch (e) {
      debugPrint('$_locationFetchError $e');
    }
  }

  Future<void> _loadCurrentUserId() async {
    final storage = Provider.of<FlutterSecureStorage>(context, listen: false);
    final token = await storage.read(key: 'token');
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length != 3) {
          throw Exception(_jwtTokenError);
        }
        final payload = parts[1];
        final decodedPayload = utf8.decode(base64.decode(base64.normalize(payload)));
        final decoded = jsonDecode(decodedPayload) as Map<String, dynamic>;
        _currentUserId = int.parse(decoded[
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
            '0');
      } catch (e) {
        debugPrint('$_userIdLoadError $e');
        _currentUserId = null;
      }
    } else {
      _currentUserId = null;
    }
  }

  Future<void> _loadCarListings() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _carListings = [];
        _updateMarkers();
      });
      _showErrorDialog(_noInternetError);
      return;
    }

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final carListings = await apiService.getCarListings();
      setState(() {
        _carListings = carListings.where((listing) {
          return _filterStrategies.every((strategy) => strategy.apply(listing));
        }).toList();
        debugPrint('Załadowano ${_carListings.length} listingów');
        _updateMarkers();
      });
    } catch (e) {
      setState(() {
        _carListings = [];
        _updateMarkers();
      });
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('failed host lookup') || errorMessage.contains('socketexception')) {
        _showErrorDialog(_noInternetError);
      } else {
        _showErrorDialog(_listingsLoadError);
      }
    }
  }

  Future<void> _loadUserRentals() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final rentals = await apiService.getUserCarRentals();
      setState(() {
        _userRentals = rentals;
        debugPrint('Załadowano ${_userRentals.length} wypożyczeń');
      });
    } catch (e) {
      debugPrint('$_rentalsLoadError $e');
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
            color: _greyColor,
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: _greyColor,
                height: 1.5,
              ),
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  _okButtonText,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
      debugPrint(
          'Dodaję marker dla ${listing.brand}, ID: ${listing.id}, współrzędne: (${listing.latitude}, ${listing.longitude})');

      if (listing.latitude.isNaN || listing.longitude.isNaN) {
        debugPrint('Błąd: Nieprawidłowe współrzędne dla markera ${listing.id}');
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
        onTap: () async {
          debugPrint('Przekierowuję do szczegółów listingu ${listing.id}');
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CarListingDetailPage(listing: listing),
            ),
          );
          if (result == true) {
            debugPrint('Wynajem zakończony, odświeżam dane w RentCarPage');
            await _loadCarListings();
            await _loadUserRentals();
          }
        },
      ));
    }

    setState(() {
      debugPrint('Zaktualizowano markery, liczba markerów: ${_markers.length}');
    });
  }

  Future<void> _setMapStyle() async {
    if (_mapController == null) return;

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final stylePath = themeProvider.isDarkMode
        ? 'assets/map_styles/dark_mode.json'
        : 'assets/map_styles/light_mode.json';

    try {
      String style = await rootBundle.loadString(stylePath);
      _mapController!.setMapStyle(style);
    } catch (e) {
      debugPrint('$_mapStyleLoadError $e');
    }
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _currentZoom = position.zoom;
      debugPrint('Zmiana zoomu: $_currentZoom');
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
    if (_mapController == null) return;

    final bounds = await _mapController!.getVisibleRegion();
    debugPrint('Widoczny obszar mapy: $bounds');

    Future.delayed(const Duration(milliseconds: 500), () {
      for (var marker in _markers) {
        bool isVisible = bounds.contains(marker.position);
        if (isVisible) {
          _mapController!.showMarkerInfoWindow(marker.markerId);
          debugPrint(
              'Pokazuję InfoWindow dla markera ${marker.markerId} na pozycji ${marker.position}');
        } else {
          _mapController!.hideMarkerInfoWindow(marker.markerId);
          debugPrint(
              'Ukrywam InfoWindow dla markera ${marker.markerId}, bo jest poza widocznym obszarem');
        }
      }
    });
  }

  void _hideAllInfoWindows() {
    if (_mapController == null) return;
    for (var marker in _markers) {
      _mapController!.hideMarkerInfoWindow(marker.markerId);
      debugPrint('Ukrywam InfoWindow dla markera ${marker.markerId}');
    }
  }

  double _calculateTotalPrice(CarRental rental) {
    final days = rental.rentalEndDate.difference(rental.rentalStartDate).inDays;
    return (days < 1 ? 1 : days) * rental.carListing.rentalPricePerDay;
  }

  int _calculateDaysUntilEnd(CarRental rental) {
    final now = DateTime.now();
    if (rental.rentalEndDate.isBefore(now)) {
      return 0;
    }
    return (rental.rentalEndDate.difference(now).inHours / 24).ceil();
  }

  void _showRentedCarsBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final activeRentals = _userRentals.where((rental) =>
            rental.rentalStatus == _rentalStatusActive).toList();

            final endedOrCanceledRentals = _userRentals.where((rental) =>
            rental.rentalStatus == _rentalStatusEnded ||
                rental.rentalStatus == _rentalStatusCanceled).toList();

            final displayRentals =
            _showEndedRentals ? endedOrCanceledRentals : activeRentals;

            return Theme(
              data: Theme.of(context).copyWith(
                dividerTheme: const DividerThemeData(color: Colors.transparent),
              ),
              child: Column(
                children: [
                  _buildShowEndedRentalsSwitch(setModalState),
                  _buildRentedRentalsList(
                      displayRentals, _showEndedRentals, setModalState),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShowEndedRentalsSwitch(StateSetter setModalState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            _showEndedRentalsSwitchText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Switch(
            value: _showEndedRentals,
            onChanged: (value) {
              setState(() {
                _showEndedRentals = value;
              });
              setModalState(() {});
            },
            activeColor: _themeColor,
          ),
        ],
      ),
    );
  }

  Widget _buildRentedRentalsList(List<CarRental> displayRentals,
      bool showEndedRentals, StateSetter setModalState) {
    if (_isRentalsLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else if (displayRentals.isEmpty) {
      return _buildNoRentalsMessage(showEndedRentals);
    } else {
      return Expanded(
        child: ListView.builder(
          itemCount: displayRentals.length,
          itemBuilder: (context, index) {
            final rental = displayRentals[index];
            return _buildRentalCard(rental, setModalState);
          },
        ),
      );
    }
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: _themeColor, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoRentalsMessage(bool showEndedRentals) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.directions_car,
            size: 48,
            color: _greyColor,
          ),
          const SizedBox(height: 16),
          Text(
            showEndedRentals ? _noEndedOrCanceledRentals : _noActiveRentals,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _greyColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRentalCard(CarRental rental, StateSetter setModalState) {
    return FutureBuilder<List<CarRentalReview>>(
      future: Provider.of<ApiService>(context, listen: false)
          .getReviewsForListing(rental.carListingId),
      builder: (context, reviewSnapshot) {
        bool canAddReview = false;
        if (reviewSnapshot.hasData) {
          final reviews = reviewSnapshot.data!;
          canAddReview = rental.rentalStatus == _rentalStatusEnded &&
              !reviews.any((review) => review.carRentalId == rental.carRentalId);
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            key: Key(rental.carRentalId.toString()),
            initiallyExpanded: false,
            leading: const Icon(
              Icons.directions_car,
              color: _themeColor,
            ),
            title: Text(
              rental.carListing.brand,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              _rentalDatesLabel
                  .replaceAll(
                  '%s', DateFormat('dd.MM.yyyy').format(rental.rentalStartDate))
                  .replaceAll(
                  '%s', DateFormat('dd.MM.yyyy').format(rental.rentalEndDate)),
              style: const TextStyle(fontSize: 14, color: _greyColor),
            ),
            trailing: _buildRentalStatusChip(rental.rentalStatus),
            children: [
              _buildRentalDetails(rental, canAddReview, setModalState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRentalStatusChip(String status) {
    Color color;
    switch (status) {
      case _rentalStatusActive:
        color = _greenColor;
        break;
      case _rentalStatusEnded:
        color = _amberColor;
        break;
      case _rentalStatusCanceled:
        color = _redColor;
        break;
      default:
        color = _greyColor;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 14,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRentalDetails(
      CarRental rental, bool canAddReview, StateSetter setModalState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            Icons.monetization_on,
            _rentalPriceLabel.replaceAll(
                '%s', _calculateTotalPrice(rental).toStringAsFixed(2)),
          ),
          const SizedBox(height: 12),
          if (rental.rentalStatus == _rentalStatusActive)
            _buildDetailRow(
              Icons.timer,
              _daysRemainingLabel
                  .replaceAll('%s', _calculateDaysUntilEnd(rental).toString()),
            ),
          if (rental.rentalStatus == _rentalStatusActive) ...[
            const SizedBox(height: 16),
            _buildCancelRentalButton(rental, setModalState),
          ],
          if (rental.rentalStatus == _rentalStatusEnded && canAddReview) ...[
            const SizedBox(height: 16),
            _buildAddReviewButton(rental, setModalState),
          ],
        ],
      ),
    );
  }

  Widget _buildAddReviewButton(CarRental rental, StateSetter setModalState) {
    return Center(
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
          backgroundColor: _themeColor,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          _addReviewButtonText,
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCancelRentalButton(CarRental rental, StateSetter setModalState) {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          final bool? confirm = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text(_cancelRentalConfirmTitle),
                content: const Text(_cancelRentalConfirmMessage),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(_noButtonText),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(_yesButtonText),
                  ),
                ],
              );
            },
          );

          if (confirm == true) {
            await _cancelRental(rental.carRentalId, setModalState);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _redColor,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          _cancelRentalButtonText,
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _cancelRental(int rentalId, StateSetter setModalState) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.deleteCarRental(rentalId);
      _showSnackBar(_cancelSuccess, _greenColor);
      await _loadUserRentals();
      setModalState(() {});
    } catch (e) {
      _showSnackBar(
          '$_cancelError ${e.toString().replaceFirst('Exception: ', '')}',
          _redColor);
    }
  }

  void _showFilterBottomSheet() {
    final brandController = TextEditingController(text: _filterBrand ?? '');
    final minSeatsController =
    TextEditingController(text: _minSeats?.toString() ?? '');
    final maxSeatsController =
    TextEditingController(text: _maxSeats?.toString() ?? '');
    final minPriceController =
    TextEditingController(text: _minPrice?.toString() ?? '');
    final maxPriceController =
    TextEditingController(text: _maxPrice?.toString() ?? '');
    final cityController = TextEditingController(text: _filterCity ?? '');
    final radiusController =
    TextEditingController(text: _filterRadius?.toString() ?? '');

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
                    _buildFilterHeader(),
                    _buildBrandFilterField(brandController),
                    _buildSeatsFilterFields(minSeatsController, maxSeatsController),
                    _buildFuelTypeFilterChips(tempFuelTypes, setModalState),
                    _buildPriceFilterFields(minPriceController, maxPriceController),
                    _buildCarTypeFilterChips(tempCarTypes, setModalState),
                    _buildLocationFilterFields(cityController, radiusController),
                    _buildFilterActionButtons(
                      brandController,
                      minSeatsController,
                      maxSeatsController,
                      tempFuelTypes,
                      minPriceController,
                      maxPriceController,
                      tempCarTypes,
                      cityController,
                      radiusController,
                      setModalState,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          _filterTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _themeColor,
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBrandFilterField(TextEditingController controller) {
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: _brandFilterLabel,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSeatsFilterFields(
      TextEditingController minController, TextEditingController maxController) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: minController,
                decoration: const InputDecoration(
                  labelText: _minSeatsLabel,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: maxController,
                decoration: const InputDecoration(
                  labelText: _maxSeatsLabel,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFuelTypeFilterChips(
      List<String> tempFuelTypes, StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          _fuelTypeLabel,
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
      ],
    );
  }

  Widget _buildPriceFilterFields(
      TextEditingController minController, TextEditingController maxController) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: minController,
                decoration: const InputDecoration(
                  labelText: _minPriceLabel,
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: maxController,
                decoration: const InputDecoration(
                  labelText: _maxPriceLabel,
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCarTypeFilterChips(
      List<String> tempCarTypes, StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          _carTypeLabel,
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
      ],
    );
  }

  Widget _buildLocationFilterFields(
      TextEditingController cityController, TextEditingController radiusController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          _locationLabel,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: cityController,
          decoration: const InputDecoration(
            labelText: _cityHint,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: radiusController,
          decoration: const InputDecoration(
            labelText: _radiusLabel,
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFilterActionButtons(
      TextEditingController brandController,
      TextEditingController minSeatsController,
      TextEditingController maxSeatsController,
      List<String> tempFuelTypes,
      TextEditingController minPriceController,
      TextEditingController maxPriceController,
      List<String> tempCarTypes,
      TextEditingController cityController,
      TextEditingController radiusController,
      StateSetter setModalState,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            _cancelButtonText,
            style: TextStyle(color: _greyColor),
          ),
        ),
        Row(
          children: [
            TextButton(
              onPressed: () async {
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
                _clearFilters();
                await _loadCarListings();
                if (mounted) {
                  Navigator.pop(context);
                  if (_carListings.isEmpty) {
                    _showErrorDialog(_noListingsMatchingCriteria);
                  }
                }
              },
              child: const Text(
                _clearFiltersButtonText,
                style: TextStyle(color: _redColor),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await _applyFilters(
                  brandController,
                  minSeatsController,
                  maxSeatsController,
                  tempFuelTypes,
                  minPriceController,
                  maxPriceController,
                  tempCarTypes,
                  cityController,
                  radiusController,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _themeColor,
                foregroundColor: Colors.white,
              ),
              child: const Text(_applyFiltersButtonText),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _applyFilters(
      TextEditingController brandController,
      TextEditingController minSeatsController,
      TextEditingController maxSeatsController,
      List<String> tempFuelTypes,
      TextEditingController minPriceController,
      TextEditingController maxPriceController,
      List<String> tempCarTypes,
      TextEditingController cityController,
      TextEditingController radiusController,
      ) async {
    setState(() {
      _filterBrand =
      brandController.text.isEmpty ? null : brandController.text;
      _minSeats = minSeatsController.text.isEmpty
          ? null
          : int.tryParse(minSeatsController.text);
      _maxSeats = maxSeatsController.text.isEmpty
          ? null
          : int.tryParse(maxSeatsController.text);
      _filterFuelTypes = List.from(tempFuelTypes);
      _minPrice = minPriceController.text.isEmpty
          ? null
          : double.tryParse(minPriceController.text);
      _maxPrice = maxPriceController.text.isEmpty
          ? null
          : double.tryParse(maxPriceController.text);
      _filterCarTypes = List.from(tempCarTypes);
      _filterCity = cityController.text.isEmpty ? null : cityController.text;
      _filterRadius = radiusController.text.isEmpty
          ? null
          : double.tryParse(radiusController.text);
    });

    if (_filterCity != null && _filterCity!.isNotEmpty) {
      try {
        final locations = await locationFromAddress(_filterCity!);
        if (locations.isNotEmpty) {
          setState(() {
            _filterCityCoordinates =
                LatLng(locations.first.latitude, locations.first.longitude);
          });
        } else {
          _showSnackBar(_cityNotFound, _redColor);
          setState(() {
            _filterCityCoordinates = null;
          });
        }
      } catch (e) {
        _showSnackBar('$_geocodingError $_filterCity', _redColor);
        setState(() {
          _filterCityCoordinates = null;
        });
      }
    } else {
      setState(() {
        _filterCityCoordinates = null;
      });
    }

    _updateFilterStrategies();
    await _loadCarListings();

    if (mounted) {
      Navigator.pop(context);

      if (_carListings.isEmpty) {
        _showErrorDialog(_noListingsMatchingCriteria);
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _filterBrand = null;
      _minSeats = null;
      _maxSeats = null;
      _filterFuelTypes = [];
      _minPrice = null;
      _maxPrice = null;
      _filterCarTypes = [];
      _filterCity = null;
      _filterRadius = null;
      _filterCityCoordinates = null;
    });
    _updateFilterStrategies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: _appBarTitle,
        onNotificationPressed: () {
          Navigator.pushNamed(context, '/notifications');
        },
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              debugPrint('Mapa utworzona, controller: $controller');
              _mapController = controller;
              _setMapStyle();
              _mapController!.animateCamera(
                CameraUpdate.newLatLng(_center),
              );
            },
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
            markers: _markers,
            onCameraMove: _onCameraMove,
          ),
          if (_isListingsLoading || _isLocationLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 10),
                    if (_isLocationLoading)
                      const Text(
                        _searchingLocationText,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FloatingActionButton.extended(
            onPressed: _showFilterBottomSheet,
            backgroundColor: _themeColor,
            foregroundColor: Colors.white,
            label: const Text(_filterButtonText),
            icon: const Icon(Icons.filter_list),
            heroTag: 'filterButton',
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: _showRentedCarsBottomSheet,
            backgroundColor: _themeColor,
            foregroundColor: Colors.white,
            label: const Text(_rentedCarsButtonText),
            icon: const Icon(Icons.car_rental),
            heroTag: 'rentedCarsButton',
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}