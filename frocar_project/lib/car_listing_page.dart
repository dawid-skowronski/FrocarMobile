import 'package:flutter/material.dart';
import 'package:test_project/models/car_listing.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'package:test_project/widgets/map_picker.dart';
import 'package:provider/provider.dart';
import 'package:test_project/providers/theme_provider.dart';

class CarListingPage extends StatefulWidget {
  @override
  _CarListingPageState createState() => _CarListingPageState();
}

class _CarListingPageState extends State<CarListingPage> {
  final _formKey = GlobalKey<FormState>();
  final brandController = TextEditingController();
  final engineCapacityController = TextEditingController();
  final seatsController = TextEditingController();
  String? fuelType;
  String? carType;
  List<String> features = [];
  final featureController = TextEditingController();
  double? latitude;
  double? longitude;
  bool isLoading = false;

  final List<String> fuelTypes = ['Benzyna', 'Diesel', 'Elektryczny', 'Hybryda', 'LPG'];
  final List<String> carTypes = [
    'SUV', 'Sedan', 'Kombi', 'Hatchback', 'Coupe', 'Cabrio', 'Pickup', 'Van', 'Minivan',
    'Crossover', 'Limuzyna', 'Microcar', 'Roadster', 'Muscle car', 'Terenowy', 'Targa'
  ];

  Future<void> _selectLocation() async {
    final selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapPicker()),
    );
    if (selectedLocation != null) {
      setState(() {
        latitude = selectedLocation.latitude;
        longitude = selectedLocation.longitude;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() && latitude != null && longitude != null) {
      setState(() {
        isLoading = true;
      });
      try {
        final carListing = CarListing(
          id: 0,
          brand: brandController.text,
          engineCapacity: double.parse(engineCapacityController.text),
          fuelType: fuelType!,
          seats: int.parse(seatsController.text),
          carType: carType!,
          features: features,
          latitude: latitude!,
          longitude: longitude!,
        );
        await ApiService().createCarListing(carListing);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ogłoszenie dodane pomyślnie')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd podczas dodawania ogłoszenia: $e')),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wypełnij wszystkie pola i wybierz lokalizację')),
      );
    }
  }

  InputDecoration _inputDecoration(String hintText) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    return InputDecoration(
      hintText: hintText,
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
      appBar: CustomAppBar(title: "Dodaj ogłoszenie"),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
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
              SizedBox(height: 12),
              TextFormField(
                controller: engineCapacityController,
                decoration: _inputDecoration('Pojemność silnika (l)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Pole wymagane';
                  if (double.tryParse(value) == null) return 'Podaj liczbę';
                  return null;
                },
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
              SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showSelectionDialog(context, 'Wybierz rodzaj paliwa', fuelTypes, (selected) {
                  setState(() => fuelType = selected);
                }),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900]! : Colors.grey[200]!,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDarkMode ? Colors.grey : Colors.grey[400]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(fuelType ?? 'Wybierz rodzaj paliwa', style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black)),
                      Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white : Colors.black),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: seatsController,
                decoration: _inputDecoration('Liczba miejsc'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Pole wymagane';
                  if (int.tryParse(value) == null) return 'Podaj liczbę';
                  return null;
                },
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
              SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showSelectionDialog(context, 'Wybierz typ samochodu', carTypes, (selected) {
                  setState(() => carType = selected);
                }),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900]! : Colors.grey[200]!,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDarkMode ? Colors.grey : Colors.grey[400]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(carType ?? 'Wybierz typ samochodu', style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black)),
                      Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white : Colors.black),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.only(left: 5),
                child: Text('Dodatki:', style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: featureController,
                      decoration: _inputDecoration('Np. Klimatyzacja'),
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    ),
                  ),
                  SizedBox(width: 8),
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
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(16),
                      backgroundColor: Color(0xFF375534),
                    ),
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Wyświetlanie dodanych dodatków z możliwością usunięcia
              Wrap(
                spacing: 8, 
                runSpacing: 8,
                children: features.map((feature) {
                  return Chip(
                    label: Text(feature, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                    backgroundColor: isDarkMode ? Colors.grey[900]! : Colors.grey[200]!,
                    deleteIcon: Icon(Icons.close, color: isDarkMode ? Colors.white : Colors.black),
                    deleteIconColor: isDarkMode ? Colors.white : Colors.black,
                    onDeleted: () {
                      setState(() {
                        features.remove(feature);
                      });
                    },
                  );
                }).toList(),
              ),

              SizedBox(height: 24),
              // Wybór lokalizacji
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF375534),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                  child: Text('Wybierz lokalizację na mapie', style: TextStyle(color: Colors.white)),
                ),
              ),
              SizedBox(height: 16),

              // Wyświetlanie wybranej lokalizacji
              if (latitude != null && longitude != null) ...[
                Padding(
                  padding: EdgeInsets.all(5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Wybrana lokalizacja:', style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                      SizedBox(height: 8),
                      Text('Szerokość: $latitude', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                      Text('Długość: $longitude', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 16),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF375534),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                  child: Text('Dodaj ogłoszenie', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSelectionDialog(BuildContext context, String title, List<String> options, Function(String) onSelected) {
    return showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: 400,
          child: Column(
            children: [
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(options[index], style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
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