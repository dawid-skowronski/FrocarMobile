import 'dart:async';
import 'package:flutter/material.dart';
import 'package:test_project/models/car_listing.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'car_listing_page.dart' as listingPage;
import 'car_listing_detail_page.dart' as detailPage;

const String _appBarTitle = "Zarządzaj ogłoszeniami";
const String _addListingButtonText = 'Dodaj nowe ogłoszenie';
const String _myListingsHeader = 'Moje ogłoszenia';
const String _noListingsMessage = 'Brak ogłoszeń';
const String _listingTypeLabel = 'Typ:';
const String _statusApproved = 'Aktualne';
const String _statusPending = 'Oczekujące';
const String _statusRented = 'Wypożyczone';
const String _connectionErrorMessage = 'Błąd połączenia z serwerem. Spróbuj ponownie później.';
const String _unauthorizedErrorMessage = 'Nieautoryzowany dostęp. Zaloguj się ponownie.';
const String _genericFetchErrorMessage = 'Wystąpił problem podczas pobierania ogłoszeń.';

class OfferCarPage extends StatefulWidget {
  final ApiService apiService;

  OfferCarPage({
    Key? key,
    ApiService? apiService,
  })  : apiService = apiService ?? ApiService(),
        super(key: key);

  @override
  _OfferCarPageState createState() => _OfferCarPageState();
}

class _OfferCarPageState extends State<OfferCarPage> {
  List<CarListing> _userListings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserListings();
    });
  }

  void _setLoadingState(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  void _setUserListings(List<CarListing> listings) {
    if (mounted) {
      setState(() {
        _userListings = listings;
      });
    }
  }

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

  Future<void> _loadUserListings() async {
    _setLoadingState(true);
    try {
      final listings = await widget.apiService.getUserCarListings();
      _setUserListings(listings);
    } catch (e) {
      final errorMsg = _mapErrorMessage(e.toString());
      _showSnackBar(errorMsg, Colors.red);
      _setUserListings([]);
    } finally {
      _setLoadingState(false);
    }
  }

  String _mapErrorMessage(String raw) {
    final message = raw.replaceFirst('Exception: ', '');
    if (message.contains('timeout')) {
      return _connectionErrorMessage;
    } else if (message.contains('401')) {
      return _unauthorizedErrorMessage;
    } else {
      return _genericFetchErrorMessage;
    }
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAddListingCard(),
            const SizedBox(height: 16),
            _buildMyListingsHeader(),
            const SizedBox(height: 8),
            _buildListingsContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddListingCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => const listingPage.CarListingPage(),
          ),
        ).then((_) => _loadUserListings());
      },
      child: Card(
        color: const Color(0xFF375534),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add, size: 32, color: Colors.white),
              SizedBox(width: 8),
              Text(
                _addListingButtonText,
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyListingsHeader() {
    return const Text(
      _myListingsHeader,
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildListingsContent() {
    if (_isLoading) {
      return _buildLoadingIndicator();
    } else if (_userListings.isEmpty) {
      return _buildNoListingsMessage();
    } else {
      return _buildListingsList();
    }
  }

  Widget _buildLoadingIndicator() {
    return const Expanded(
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildNoListingsMessage() {
    return const Expanded(
      child: Center(
        child: Text(
          _noListingsMessage,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildListingsList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _userListings.length,
        itemBuilder: (context, index) {
          final listing = _userListings[index];
          return _buildListingCard(listing);
        },
      ),
    );
  }

  Widget _buildListingCard(CarListing listing) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.directions_car,
          color: Color(0xFF375534),
        ),
        title: Text(
          listing.brand,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$_listingTypeLabel ${listing.carType}',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusChip(listing.isApproved, listing.isAvailable),
            if (!listing.isAvailable)
              const SizedBox(width: 8),
            if (!listing.isAvailable)
              _buildRentedChip(),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => detailPage.CarListingDetailPage(
                listing: listing,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(bool isApproved, bool isAvailable) {
    String text;
    Color color;
    if (isApproved) {
      text = _statusApproved;
      color = Colors.green;
    } else {
      text = _statusPending;
      color = Colors.yellow[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRentedChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        _statusRented,
        style: TextStyle(
          fontSize: 14,
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
