import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/car_listing.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';

const String _appBarTitle = 'Wypożycz auto';
const String _pageTitlePrefix = 'Wypożycz';
const String _startDateLabel = 'Data rozpoczęcia';
const String _endDateLabel = 'Data zakończenia';
const String _startDateValidationMessage = 'Wybierz datę rozpoczęcia';
const String _endDateValidationMessage = 'Wybierz datę zakończenia';
const String _endDateBeforeStartDateMessage = 'Data zakończenia musi być po rozpoczęciu';
const String _totalPricePrefix = 'Całkowita kwota:';
const String _selectDatesMessage = 'Wybierz daty, aby zobaczyć kwotę';
const String _rentButtonText = 'Wypożycz';
const String _rentalSuccessMessage = 'Wypożyczenie zostało dodane';
const String _errorMessagePrefix = 'Błąd:';
const Color _themeColor = Color(0xFF375534);
const Color _greyColor = Colors.grey;
const Color _whiteColor = Colors.white;

class RentFormPage extends StatefulWidget {
  final CarListing listing;

  const RentFormPage({super.key, required this.listing});

  @override
  _RentFormPageState createState() => _RentFormPageState();
}

class _RentFormPageState extends State<RentFormPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  final _formKey = GlobalKey<FormState>();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _endDate = null;
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate!.add(const Duration(days: 1)),
      firstDate: _startDate!.add(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$_errorMessagePrefix $message')),
    );
  }

  Future<void> _submitRental() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.createCarRental(
        widget.listing.id,
        _startDate!,
        _endDate!,
      );

      _showSuccessSnackBar(_rentalSuccessMessage);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  double _calculateTotalPrice() {
    if (_startDate == null || _endDate == null) return 0.0;
    final days = _endDate!.difference(_startDate!).inDays;
    return (days > 0 ? days : 1) * widget.listing.rentalPricePerDay;
  }

  Widget _buildPageTitle() {
    return Text(
      '$_pageTitlePrefix ${widget.listing.brand}',
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDateField({
    required String labelText,
    required DateTime? date,
    required VoidCallback onTap,
    required String? Function(String?) validator,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextFormField(
          decoration: InputDecoration(
            labelText: labelText,
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          controller: TextEditingController(
            text: date != null ? _dateFormat.format(date) : '',
          ),
          validator: validator,
        ),
      ),
    );
  }

  Widget _buildTotalPriceDisplay() {
    return Center(
      child: Text(
        _startDate != null && _endDate != null
            ? '$_totalPricePrefix ${_calculateTotalPrice().toStringAsFixed(2)} PLN'
            : _selectDatesMessage,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _greyColor,
        ),
      ),
    );
  }

  Widget _buildRentButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _submitRental,
        style: ElevatedButton.styleFrom(
          backgroundColor: _themeColor,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(
          _rentButtonText,
          style: TextStyle(fontSize: 16, color: _whiteColor),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _appBarTitle,
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
              _buildPageTitle(),
              const SizedBox(height: 16),
              _buildDateField(
                labelText: _startDateLabel,
                date: _startDate,
                onTap: _selectStartDate,
                validator: (_) => _startDate == null ? _startDateValidationMessage : null,
              ),
              const SizedBox(height: 16),
              _buildDateField(
                labelText: _endDateLabel,
                date: _endDate,
                onTap: _selectEndDate,
                validator: (_) {
                  if (_endDate == null) return _endDateValidationMessage;
                  if (_startDate != null && _endDate!.isBefore(_startDate!)) {
                    return _endDateBeforeStartDateMessage;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTotalPriceDisplay(),
              const SizedBox(height: 24),
              _buildRentButton(),
            ],
          ),
        ),
      ),
    );
  }
}
