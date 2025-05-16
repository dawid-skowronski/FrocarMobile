import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/car_listing.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';

class RentFormPage extends StatefulWidget {
  final CarListing listing;

  const RentFormPage({super.key, required this.listing});

  @override
  _RentFormPageState createState() => _RentFormPageState();
}

class _RentFormPageState extends State<RentFormPage> {
  DateTime? startDate;
  DateTime? endDate;
  final _formKey = GlobalKey<FormState>();

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        endDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        await apiService.createCarRental(
          widget.listing.id,
          startDate!,
          endDate!,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wypożyczenie zostało dodane')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e')),
        );
      }
    }
  }

  double _calculateTotalPrice() {
    if (startDate == null || endDate == null) {
      return 0.0;
    }
    final days = endDate!.difference(startDate!).inDays;
    return days * widget.listing.rentalPricePerDay;
  }

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Color(0xFF375534);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Wypożycz auto',
        onNotificationPressed: () {
          Navigator.pushNamed(context, '/notifications');
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wypożycz ${widget.listing.brand}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Data rozpoczęcia',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _selectStartDate,
                validator: (value) {
                  if (startDate == null) {
                    return 'Wybierz datę rozpoczęcia';
                  }
                  return null;
                },
                controller: TextEditingController(
                  text: startDate != null ? startDate.toString().substring(0, 10) : '',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Data zakończenia',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _selectEndDate,
                validator: (value) {
                  if (endDate == null) {
                    return 'Wybierz datę zakończenia';
                  }
                  if (startDate != null && endDate!.isBefore(startDate!)) {
                    return 'Data zakończenia musi być po dacie rozpoczęcia';
                  }
                  return null;
                },
                controller: TextEditingController(
                  text: endDate != null ? endDate.toString().substring(0, 10) : '',
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  startDate != null && endDate != null
                      ? 'Całkowita kwota: ${_calculateTotalPrice().toStringAsFixed(2)} PLN'
                      : 'Wybierz daty, aby zobaczyć kwotę',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text(
                    'Wypożycz',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}