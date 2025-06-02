import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../widgets/custom_app_bar.dart';
import '../models/car_listing.dart';
import '../services/api_service.dart';
import '../widgets/map_picker.dart';
import '../providers/theme_provider.dart';

const String _addListingTitle = "Dodaj ogłoszenie";
const String _editListingTitle = "Edytuj ogłoszenie";
const String _brandHint = 'Marka';
const String _engineCapacityHint = 'Pojemność silnika (l)';
const String _fuelTypeSelectionTitle = 'Wybierz rodzaj paliwa';
const String _fuelTypeHint = 'Wybierz rodzaj paliwa';
const String _seatsHint = 'Liczba miejsc';
const String _carTypeSelectionTitle = 'Wybierz typ samochodu';
const String _carTypeHint = 'Wybierz typ samochodu';
const String _rentalPriceHint = 'Cena wynajmu za dzień (PLN)';
const String _featuresLabel = 'Dodatki:';
const String _featureHint = 'Np. Klimatyzacja';
const String _selectLocationButton = 'Wybierz lokalizację na mapie';
const String _selectedLocationLabel = 'Wybrana lokalizacja:';
const String _addressLabel = 'Adres:';
const String _addListingButton = 'Dodaj ogłoszenie';
const String _saveChangesButton = 'Zapisz zmiany';

const String _fieldRequired = 'Pole wymagane.';
const String _invalidNumber = 'Podaj prawidłową liczbę.';
const String _valueGreaterThanZero = 'Musi być większa od 0.';
const String _addressNotAvailableOffline = 'Adres niedostępny – brak połączenia z internetem.';
const String _connectionTimeout = 'Przekroczono limit czasu połączenia.';
const String _addressFetchFailed = 'Nie udało się pobrać adresu. Spróbuj ponownie.';
const String _noAddressFound = 'Nie udało się znaleźć adresu.';
const String _noInternetConnection = 'Brak połączenia z internetem. Sprawdź swoje połączenie.';
const String _listingSavedLocally = 'Ogłoszenie zapisane lokalnie. Zostanie dodane, gdy wrócisz online.';
const String _listingAddedSuccessfully = 'Ogłoszenie dodane pomyślnie!';
const String _listingUpdatedSuccessfully = 'Ogłoszenie zaktualizowane pomyślnie!';
const String _syncSuccess = 'Ogłoszenie zsynchronizowane pomyślnie!';
const String _syncFailed = 'Nie udało się zsynchronizować ogłoszenia. Spróbuj ponownie.';
const String _missingToken = 'Brak tokenu. Zaloguj się ponownie.';
const String _loginRequired = 'Musisz się zalogować, aby dodać ogłoszenie.';
const String _saveFailed = 'Nie udało się zapisać ogłoszenia. Spróbuj ponownie.';
const String _fillAllFields = 'Proszę wypełnić wszystkie pola i wybrać lokalizację.';


class CarListingPage extends StatefulWidget {
  final CarListing? listing;

  const CarListingPage({super.key, this.listing});

  @override
  _CarListingPageState createState() => _CarListingPageState();
}

class _CarListingPageState extends State<CarListingPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _engineCapacityController = TextEditingController();
  final TextEditingController _seatsController = TextEditingController();
  final TextEditingController _rentalPriceController = TextEditingController();
  String? _selectedFuelType;
  String? _selectedCarType;
  final List<String> _features = [];
  final TextEditingController _featureController = TextEditingController();
  double? _latitude;
  double? _longitude;
  String? _displayAddress;
  bool _isLoading = false;
  final _storage = const FlutterSecureStorage();

  final List<String> _fuelTypes = [
    'Benzyna', 'Diesel', 'Elektryczny', 'Hybryda', 'LPG'
  ];
  final List<String> _carTypes = [
    'SUV', 'Sedan', 'Kombi', 'Hatchback', 'Coupe', 'Cabrio', 'Pickup', 'Van',
    'Minivan', 'Crossover', 'Limuzyna', 'Microcar', 'Roadster', 'Muscle car', 'Terenowy', 'Targa'
  ];

  @override
  void initState() {
    super.initState();
    _initializeFormFields();
  }

  void _initializeFormFields() {
    if (widget.listing != null) {
      _brandController.text = widget.listing!.brand;
      _engineCapacityController.text = widget.listing!.engineCapacity.toString();
      _seatsController.text = widget.listing!.seats.toString();
      _rentalPriceController.text = widget.listing!.rentalPricePerDay.toString();
      _selectedFuelType = widget.listing!.fuelType;
      _selectedCarType = widget.listing!.carType;
      _features.addAll(widget.listing!.features);
      _latitude = widget.listing!.latitude;
      _longitude = widget.listing!.longitude;
      _tryReverseGeocode(_latitude!, _longitude!);
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _engineCapacityController.dispose();
    _seatsController.dispose();
    _rentalPriceController.dispose();
    _featureController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _selectLocation() async {
    final selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapPicker()),
    );
    if (selectedLocation != null) {
      setState(() {
        _latitude = selectedLocation.latitude;
        _longitude = selectedLocation.longitude;
        _displayAddress = null;
      });
      await _tryReverseGeocode(_latitude!, _longitude!);
    }
  }

  Future<void> _tryReverseGeocode(double lat, double lon) async {
    if (!(await _isOnline())) {
      setState(() {
        _displayAddress = _addressNotAvailableOffline;
      });
      return;
    }

    _setLoadingState(true);

    try {
      await Future.delayed(const Duration(seconds: 1));
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1');
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'FrogCarApp/1.0 (jakub.trznadel@studenci.collegiumwitelona.pl)',
        },
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception(_connectionTimeout);
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'];
        if (address != null) {
          final street = address['road'] ?? '';
          final houseNumber = address['house_number'] ?? '';
          final state = address['state'] ?? '';
          final city = address['city'] ?? address['town'] ?? address['village'] ?? '';
          final postcode = address['postcode'] ?? '';
          setState(() {
            _displayAddress = '$street, $houseNumber, $state, $city, $postcode';
          });
        } else {
          setState(() {
            _displayAddress = _noAddressFound;
          });
        }
      } else {
        throw Exception('$_addressFetchFailed (${response.statusCode})');
      }
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('failed host lookup')) {
        errorMessage = _noInternetConnection;
      } else if (e.toString().contains(_connectionTimeout)) {
        errorMessage = _connectionTimeout;
      } else {
        errorMessage = _addressFetchFailed;
      }
      _showSnackBar(errorMessage, Colors.redAccent);
      setState(() {
        _displayAddress = _addressFetchFailed;
      });
    } finally {
      _setLoadingState(false);
    }
  }

  Future<bool> _isOnline() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _saveListingLocally(CarListing carListing) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pendingListings = prefs.getStringList('pending_listings') ?? [];
    pendingListings.add(json.encode(carListing.toJson()));
    await prefs.setStringList('pending_listings', pendingListings);
    debugPrint('Ogłoszenie zapisane lokalnie: ${carListing.brand}');
  }

  Future<void> _syncPendingListings() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pendingListings = prefs.getStringList('pending_listings') ?? [];

    if (pendingListings.isEmpty) return;

    for (String listingJson in List.from(pendingListings)) {
      try {
        final carListing = CarListing.fromJson(json.decode(listingJson));
        await ApiService().createCarListing(carListing);
        pendingListings.remove(listingJson);
        await prefs.setStringList('pending_listings', pendingListings);
        _showSnackBar(_syncSuccess, Colors.green);
      } catch (e) {
        _showSnackBar(_syncFailed, Colors.redAccent);
        debugPrint('Błąd synchronizacji ogłoszenia: $e');
        return;
      }
    }
  }

  void _setLoadingState(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  CarListing _buildCarListing() {
    return CarListingBuilder()
        .setId(widget.listing?.id ?? 0)
        .setBrand(_brandController.text)
        .setEngineCapacity(double.parse(_engineCapacityController.text))
        .setFuelType(_selectedFuelType!)
        .setSeats(int.parse(_seatsController.text))
        .setCarType(_selectedCarType!)
        .setFeatures(_features)
        .setLatitude(_latitude!)
        .setLongitude(_longitude!)
        .setUserId(widget.listing?.userId ?? 0)
        .setIsAvailable(widget.listing?.isAvailable ?? true)
        .setRentalPricePerDay(double.parse(_rentalPriceController.text))
        .setIsApproved(widget.listing?.isApproved ?? false)
        .setAverageRating(widget.listing?.averageRating ?? 0.0)
        .build();
  }

  Future<void> _submit() async {
    if (!_validateForm()) {
      _showSnackBar(_fillAllFields, Colors.redAccent);
      return;
    }

    _setLoadingState(true);

    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception(_missingToken);
      }

      final carListing = _buildCarListing();
      bool isOnline = await _isOnline();

      if (isOnline) {
        await _handleOnlineSubmission(carListing);
      } else {
        await _handleOfflineSubmission(carListing);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      String errorMessage = e.toString().contains(_missingToken) ? _loginRequired : _saveFailed;
      _showSnackBar(errorMessage, Colors.redAccent);
      debugPrint('Błąd podczas zapisywania ogłoszenia: $e');
    } finally {
      _setLoadingState(false);
    }
  }

  bool _validateForm() {
    return _formKey.currentState!.validate() &&
        _latitude != null &&
        _longitude != null &&
        _selectedFuelType != null &&
        _selectedCarType != null;
  }

  Future<void> _handleOnlineSubmission(CarListing carListing) async {
    if (widget.listing == null) {
      await ApiService().createCarListing(carListing);
      _showSnackBar(_listingAddedSuccessfully, Colors.green);
      await _syncPendingListings();
    } else {
      await ApiService().updateCarListing(carListing);
      _showSnackBar(_listingUpdatedSuccessfully, Colors.green);
    }
  }

  Future<void> _handleOfflineSubmission(CarListing carListing) async {
    await _saveListingLocally(carListing);
    _showSnackBar(_listingSavedLocally, Colors.orange);
  }

  InputDecoration _inputDecoration(String hintText) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    return InputDecoration(
      hintText: hintText,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      filled: true,
      fillColor: isDarkMode ? Colors.grey[900]! : Colors.grey[200]!,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDarkMode ? Colors.grey : Colors.grey[400]!),
      ),
      hintStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.listing == null ? _addListingTitle : _editListingTitle,
        onNotificationPressed: () {
          Navigator.pushNamed(context, '/notifications');
        },
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : _buildFormContent(isDarkMode),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildFormContent(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBrandField(isDarkMode),
            const SizedBox(height: 12),
            _buildEngineCapacityField(isDarkMode),
            const SizedBox(height: 12),
            _buildFuelTypeDropdown(isDarkMode),
            const SizedBox(height: 12),
            _buildSeatsField(isDarkMode),
            const SizedBox(height: 12),
            _buildCarTypeDropdown(isDarkMode),
            const SizedBox(height: 12),
            _buildRentalPriceField(isDarkMode),
            const SizedBox(height: 12),
            _buildFeaturesInputSection(isDarkMode),
            const SizedBox(height: 16),
            _buildFeaturesChips(isDarkMode),
            const SizedBox(height: 24),
            _buildLocationPickerButton(),
            const SizedBox(height: 16),
            if (_displayAddress != null) _buildSelectedLocationDisplay(isDarkMode),
            const SizedBox(height: 16),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandField(bool isDarkMode) {
    return TextFormField(
      controller: _brandController,
      decoration: _inputDecoration(_brandHint),
      validator: (value) => value!.isEmpty ? _fieldRequired : null,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
    );
  }

  Widget _buildEngineCapacityField(bool isDarkMode) {
    return TextFormField(
      controller: _engineCapacityController,
      decoration: _inputDecoration(_engineCapacityHint),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value!.isEmpty) return _fieldRequired;
        if (double.tryParse(value) == null) return _invalidNumber;
        if (double.parse(value) <= 0) return 'Pojemność silnika $_valueGreaterThanZero';
        return null;
      },
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
    );
  }

  Widget _buildFuelTypeDropdown(bool isDarkMode) {
    return GestureDetector(
      onTap: () => _showSelectionDialog(
          context, _fuelTypeSelectionTitle, _fuelTypes, (selected) {
        setState(() => _selectedFuelType = selected);
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900]! : Colors.grey[200]!,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDarkMode ? Colors.grey : Colors.grey[400]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_selectedFuelType ?? _fuelTypeHint,
                style: TextStyle(
                    fontSize: 16, color: isDarkMode ? Colors.white : Colors.black)),
            Icon(Icons.arrow_drop_down,
                color: isDarkMode ? Colors.white : Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatsField(bool isDarkMode) {
    return TextFormField(
      controller: _seatsController,
      decoration: _inputDecoration(_seatsHint),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value!.isEmpty) return _fieldRequired;
        if (int.tryParse(value) == null) return _invalidNumber;
        if (int.parse(value) <= 0) return 'Liczba miejsc $_valueGreaterThanZero';
        return null;
      },
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
    );
  }

  Widget _buildCarTypeDropdown(bool isDarkMode) {
    return GestureDetector(
      onTap: () => _showSelectionDialog(
          context, _carTypeSelectionTitle, _carTypes, (selected) {
        setState(() => _selectedCarType = selected);
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900]! : Colors.grey[200]!,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDarkMode ? Colors.grey : Colors.grey[400]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_selectedCarType ?? _carTypeHint,
                style: TextStyle(
                    fontSize: 16, color: isDarkMode ? Colors.white : Colors.black)),
            Icon(Icons.arrow_drop_down,
                color: isDarkMode ? Colors.white : Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildRentalPriceField(bool isDarkMode) {
    return TextFormField(
      controller: _rentalPriceController,
      decoration: _inputDecoration(_rentalPriceHint),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value!.isEmpty) return _fieldRequired;
        if (double.tryParse(value) == null) return _invalidNumber;
        if (double.parse(value) <= 0) return 'Cena $_valueGreaterThanZero';
        return null;
      },
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
    );
  }

  Widget _buildFeaturesInputSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(_featuresLabel,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _featureController,
                decoration: _inputDecoration(_featureHint),
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (_featureController.text.isNotEmpty) {
                  setState(() {
                    _features.add(_featureController.text);
                    _featureController.clear();
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(16),
                backgroundColor: const Color(0xFF375534),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturesChips(bool isDarkMode) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _features.map((feature) {
        return Chip(
          label: Text(feature,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          backgroundColor: isDarkMode ? Colors.grey[900]! : Colors.grey[200]!,
          deleteIcon: Icon(Icons.close,
              color: isDarkMode ? Colors.white : Colors.black),
          onDeleted: () {
            setState(() {
              _features.remove(feature);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildLocationPickerButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectLocation,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF375534),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18),
        ),
        child: const Text(_selectLocationButton,
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildSelectedLocationDisplay(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_selectedLocationLabel,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          Text('$_addressLabel $_displayAddress',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF375534),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18),
        ),
        child: Text(
          widget.listing == null ? _addListingButton : _saveChangesButton,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _showSelectionDialog(
      BuildContext context, String title, List<String> options, Function(String) onSelected) {
    return showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color)),
              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(options[index],
                          style: TextStyle(
                              color: Theme.of(context).textTheme.bodyLarge?.color)),
                      onTap: () {
                        onSelected(options[index]);
                        Navigator.pop(context);
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
  }
}
