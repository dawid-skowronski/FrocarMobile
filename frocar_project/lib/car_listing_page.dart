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

class CarListingPage extends StatefulWidget {
  final CarListing? listing; // Opcjonalny parametr dla edycji

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
    // Jeśli przekazano listing, wstępnie wypełnij formularz
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
      _reverseGeocode(latitude!, longitude!); // Pobierz adres
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
      await _reverseGeocode(latitude!, longitude!);
    }
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
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
          'User-Agent': 'FrogCarApp/1.0 (jakub.trznadel@studenci.collegiumwitelona.pl)',
        },
      );

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
            displayAddress = '$street, $houseNumber, $state, $city, $postcode';
          });
        } else {
          setState(() {
            displayAddress = 'Nie znaleziono adresu';
          });
        }
      } else {
        throw Exception('Błąd podczas odwrotnego geokodowania: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd podczas pobierania adresu: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() {
        displayAddress = 'Nie udało się pobrać adresu';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
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
          averageRating: widget.listing?.averageRating ?? 0.0, // Dodaj to
        );
        if (widget.listing == null) {
          // Dodawanie nowego ogłoszenia
          await ApiService().createCarListing(carListing);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ogłoszenie dodane pomyślnie'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Edycja istniejącego ogłoszenia
          await ApiService().updateCarListing(carListing);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ogłoszenie zaktualizowane pomyślnie'),
              backgroundColor: Colors.green,
            ),
          );
        }
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas zapisywania ogłoszenia: $e'),
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
          content: Text('Wypełnij wszystkie pola i wybierz lokalizację'),
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
      appBar: CustomAppBar(title: widget.listing == null ? "Dodaj ogłoszenie" : "Edytuj ogłoszenie"),
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
                validator: (value) => value!.isEmpty ? 'Pole wymagane' : null,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: engineCapacityController,
                decoration: _inputDecoration('Pojemność silnika (l)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Pole wymagane';
                  if (double.tryParse(value) == null) return 'Podaj liczbę';
                  if (double.parse(value) <= 0) return 'Pojemność musi być większa od 0';
                  return null;
                },
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showSelectionDialog(context, 'Wybierz rodzaj paliwa', fuelTypes,
                        (selected) {
                      setState(() => fuelType = selected);
                    }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900]! : Colors.grey[200]!,
                    borderRadius: BorderRadius.circular(12),
                    border:
                    Border.all(color: isDarkMode ? Colors.grey : Colors.grey[400]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(fuelType ?? 'Wybierz rodzaj paliwa',
                          style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white : Colors.black)),
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
                  if (value!.isEmpty) return 'Pole wymagane';
                  if (int.tryParse(value) == null) return 'Podaj liczbę';
                  if (int.parse(value) <= 0) return 'Liczba miejsc musi być większa od 0';
                  return null;
                },
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showSelectionDialog(context, 'Wybierz typ samochodu', carTypes,
                        (selected) {
                      setState(() => carType = selected);
                    }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900]! : Colors.grey[200]!,
                    borderRadius: BorderRadius.circular(12),
                    border:
                    Border.all(color: isDarkMode ? Colors.grey : Colors.grey[400]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(carType ?? 'Wybierz typ samochodu',
                          style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white : Colors.black)),
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
                  if (value!.isEmpty) return 'Pole wymagane';
                  if (double.tryParse(value) == null) return 'Podaj liczbę';
                  if (double.parse(value) <= 0) return 'Cena musi być większa od 0';
                  return null;
                },
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
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
                      style:
                      TextStyle(color: isDarkMode ? Colors.white : Colors.black),
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
                              color: isDarkMode ? Colors.white : Colors.black)),
                      const SizedBox(height: 8),
                      Text('Adres: $displayAddress',
                          style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black)),
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
                    widget.listing == null ? 'Dodaj ogłoszenie' : 'Zapisz zmiany',
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