import 'package:flutter/material.dart';
import 'package:test_project/models/car_listing.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'package:test_project/widgets/map_picker.dart';
import 'package:provider/provider.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CarListingPage extends StatefulWidget {
  final CarListing? listing;

  const CarListingPage({super.key, this.listing});

  @override
  _CarListingPageState createState() => _CarListingPageState();
}

class _CarListingPageState extends State<CarListingPage> {
  final _formKey = GlobalKey<FormState>();
  final brandController = TextEditingController();
  final engineCapacityController = TextEditingController();
  final seatsController = TextEditingController();
  final rentalPriceController = TextEditingController();
  String? fuelType;
  String? carType;
  List<String> features = [];
  final featureController = TextEditingController();
  double? latitude;
  double? longitude;
  String? displayAddress;
  bool isLoading = false;
  final _storage = const FlutterSecureStorage();

  final List<String> fuelTypes = [
    'Benzyna',
    'Diesel',
    'Elektryczny',
    'Hybryda',
    'LPG'
  ];
  final List<String> carTypes = [
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

  @override
  void initState() {
    super.initState();
    if (widget.listing != null) {
      brandController.text = widget.listing!.brand;
      engineCapacityController.text = widget.listing!.engineCapacity.toString();
      seatsController.text = widget.listing!.seats.toString();
      rentalPriceController.text = widget.listing!.rentalPricePerDay.toString();
      fuelType = widget.listing!.fuelType;
      carType = widget.listing!.carType;
      features = List.from(widget.listing!.features);
      latitude = widget.listing!.latitude;
      longitude = widget.listing!.longitude;
      _tryReverseGeocode(latitude!, longitude!);
    }
  }

  Future<void> _selectLocation() async {
    final selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapPicker()),
    );
    if (selectedLocation != null) {
      setState(() {
        latitude = selectedLocation.latitude;
        longitude = selectedLocation.longitude;
        displayAddress = null;
      });

      await _tryReverseGeocode(latitude!, longitude!);
    }
  }

  Future<void> _tryReverseGeocode(double lat, double lon) async {
    bool isOnline = await _isOnline();
    if (!isOnline) {
      setState(() {
        displayAddress = 'Adres niedostępny – brak połączenia z internetem.';
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1');
      final response = await http.get(
        url,
        headers: {
          'User-Agent':
          'FrogCarApp/1.0 (jakub.trznadel@studenci.collegiumwitelona.pl)',
        },
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Przekroczono limit czasu połączenia.');
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'];
        if (address != null) {
          final street = address['road'] ?? '';
          final houseNumber = address['house_number'] ?? '';
          final state = address['state'] ?? '';
          final city =
              address['city'] ?? address['town'] ?? address['village'] ?? '';
          final postcode = address['postcode'] ?? '';
          setState(() {
            displayAddress = '$street, $houseNumber, $state, $city, $postcode';
          });
        } else {
          setState(() {
            displayAddress = 'Nie udało się znaleźć adresu.';
          });
        }
      } else {
        throw Exception('Nie udało się pobrać adresu. Spróbuj ponownie.');
      }
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('failed host lookup')) {
        errorMessage = 'Brak połączenia z internetem. Sprawdź swoje połączenie.';
      } else if (e.toString().contains('Przekroczono limit czasu')) {
        errorMessage = 'Przekroczono limit czasu. Spróbuj ponownie później.';
      } else {
        errorMessage = 'Nie udało się pobrać adresu. Spróbuj ponownie.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() {
        displayAddress = 'Nie udało się pobrać adresu.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
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
    print('Ogłoszenie zapisane lokalnie: ${carListing.brand}');
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ogłoszenie zsynchronizowane pomyślnie!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nie udało się zsynchronizować ogłoszenia. Spróbuj ponownie.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() &&
        latitude != null &&
        longitude != null &&
        fuelType != null &&
        carType != null) {
      setState(() {
        isLoading = true;
      });
      try {
        final token = await _storage.read(key: 'token');
        if (token == null) {
          throw Exception('Brak tokenu. Zaloguj się ponownie.');
        }
        final carListing = CarListing(
          id: widget.listing?.id ?? 0,
          brand: brandController.text,
          engineCapacity: double.parse(engineCapacityController.text),
          fuelType: fuelType!,
          seats: int.parse(seatsController.text),
          carType: carType!,
          features: features,
          latitude: latitude!,
          longitude: longitude!,
          userId: widget.listing?.userId ?? 0,
          isAvailable: widget.listing?.isAvailable ?? true,
          isApproved: widget.listing?.isApproved ?? false,
          rentalPricePerDay: double.parse(rentalPriceController.text),
          averageRating: widget.listing?.averageRating ?? 0.0,
        );

        bool isOnline = await _isOnline();
        if (isOnline) {
          if (widget.listing == null) {
            await ApiService().createCarListing(carListing);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ogłoszenie dodane pomyślnie!'),
                backgroundColor: Colors.green,
              ),
            );
            await _syncPendingListings();
          } else {
            await ApiService().updateCarListing(carListing);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ogłoszenie zaktualizowane pomyślnie!'),
                backgroundColor: Colors.green,
              ),
            );
          }
          Navigator.pop(context, true);
        } else {
          await _saveListingLocally(carListing);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Ogłoszenie zapisane lokalnie. Zostanie dodane, gdy wrócisz online.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        String errorMessage;
        if (e.toString().contains('Brak tokenu')) {
          errorMessage = 'Musisz się zalogować, aby dodać ogłoszenie.';
        } else {
          errorMessage = 'Nie udało się zapisać ogłoszenia. Spróbuj ponownie.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proszę wypełnić wszystkie pola i wybrać lokalizację.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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
  void dispose() {
    brandController.dispose();
    engineCapacityController.dispose();
    seatsController.dispose();
    rentalPriceController.dispose();
    featureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.listing == null ? "Dodaj ogłoszenie" : "Edytuj ogłoszenie",
        onNotificationPressed: () {
          Navigator.pushNamed(context, '/notifications');
        },
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: brandController,
                decoration: _inputDecoration('Marka'),
                validator: (value) => value!.isEmpty ? 'Pole wymagane.' : null,
                style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: engineCapacityController,
                decoration: _inputDecoration('Pojemność silnika (l)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Pole wymagane.';
                  if (double.tryParse(value) == null) return 'Podaj prawidłową liczbę.';
                  if (double.parse(value) <= 0)
                    return 'Pojemność musi być większa od 0.';
                  return null;
                },
                style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showSelectionDialog(
                    context, 'Wybierz rodzaj paliwa', fuelTypes,
                        (selected) {
                      setState(() => fuelType = selected);
                    }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900]! : Colors.grey[200]!,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDarkMode ? Colors.grey : Colors.grey[400]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(fuelType ?? 'Wybierz rodzaj paliwa',
                          style: TextStyle(
                              fontSize: 16,
                              color:
                              isDarkMode ? Colors.white : Colors.black)),
                      Icon(Icons.arrow_drop_down,
                          color: isDarkMode ? Colors.white : Colors.black),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: seatsController,
                decoration: _inputDecoration('Liczba miejsc'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Pole wymagane.';
                  if (int.tryParse(value) == null) return 'Podaj prawidłową liczbę.';
                  if (int.parse(value) <= 0)
                    return 'Liczba miejsc musi być większa od 0.';
                  return null;
                },
                style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showSelectionDialog(
                    context, 'Wybierz typ samochodu', carTypes,
                        (selected) {
                      setState(() => carType = selected);
                    }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900]! : Colors.grey[200]!,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDarkMode ? Colors.grey : Colors.grey[400]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(carType ?? 'Wybierz typ samochodu',
                          style: TextStyle(
                              fontSize: 16,
                              color:
                              isDarkMode ? Colors.white : Colors.black)),
                      Icon(Icons.arrow_drop_down,
                          color: isDarkMode ? Colors.white : Colors.black),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: rentalPriceController,
                decoration: _inputDecoration('Cena wynajmu za dzień (PLN)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Pole wymagane.';
                  if (double.tryParse(value) == null) return 'Podaj prawidłową liczbę.';
                  if (double.parse(value) <= 0)
                    return 'Cena musi być większa od 0.';
                  return null;
                },
                style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Text('Dodatki:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: featureController,
                      decoration: _inputDecoration('Np. Klimatyzacja'),
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (featureController.text.isNotEmpty) {
                        setState(() {
                          features.add(featureController.text);
                          featureController.clear();
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
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: features.map((feature) {
                  return Chip(
                    label: Text(feature,
                        style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black)),
                    backgroundColor:
                    isDarkMode ? Colors.grey[900]! : Colors.grey[200]!,
                    deleteIcon: Icon(Icons.close,
                        color: isDarkMode ? Colors.white : Colors.black),
                    onDeleted: () {
                      setState(() {
                        features.remove(feature);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF375534),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text('Wybierz lokalizację na mapie',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              if (displayAddress != null) ...[
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Wybrana lokalizacja:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                              isDarkMode ? Colors.white : Colors.black)),
                      const SizedBox(height: 8),
                      Text('Adres: $displayAddress',
                          style: TextStyle(
                              color:
                              isDarkMode ? Colors.white : Colors.black)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF375534),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: Text(
                    widget.listing == null
                        ? 'Dodaj ogłoszenie'
                        : 'Zapisz zmiany',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
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