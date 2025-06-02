import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/car_rental_review.dart';
import '../widgets/custom_app_bar.dart';

const String _appBarTitle = "Recenzje pojazdu";
const String _loadingReviewsMessage = 'Ładowanie recenzji...';
const String _reviewsLoadErrorMessage = 'Nie udało się załadować recenzji. Sprawdź połączenie z internetem lub spróbuj ponownie później.';
const String _noReviewsYetMessage = 'Ten pojazd nie posiada jeszcze żadnych recenzji.';
const String _authorLabel = 'Autor:';
const String _noCommentAvailable = 'Brak komentarza';
const String _dateLabel = 'Data:';

class CarReviewsPage extends StatelessWidget {
  final int listingId;
  final ApiService apiService;

  CarReviewsPage({
    Key? key,
    required this.listingId,
    ApiService? apiService,
  })  : apiService = apiService ?? ApiService(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: FutureBuilder<List<CarRentalReview>>(
        future: apiService.getReviewsForListing(listingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingIndicator();
          } else if (snapshot.hasError) {
            return _buildErrorState();
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return _buildReviewsList(snapshot.data!);
          } else {
            return _buildNoReviewsMessage();
          }
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      title: _appBarTitle,
      onNotificationPressed: () {
        Navigator.pushNamed(context, '/notifications');
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          _reviewsLoadErrorMessage,
          style: TextStyle(fontSize: 16, color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildNoReviewsMessage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          _noReviewsYetMessage,
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildReviewsList(List<CarRentalReview> reviews) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return _buildReviewCard(review);
      },
    );
  }

  Widget _buildReviewCard(CarRentalReview review) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReviewHeader(review),
            const SizedBox(height: 8),
            _buildReviewComment(review),
            const SizedBox(height: 4),
            _buildReviewDateAndAuthor(review),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewHeader(CarRentalReview review) {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 20),
        const SizedBox(width: 4),
        Text(
          review.rating.toString(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$_authorLabel ${review.user.username}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewComment(CarRentalReview review) {
    return Text(
      review.comment?.isNotEmpty == true
          ? review.comment!
          : _noCommentAvailable,
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildReviewDateAndAuthor(CarRentalReview review) {
    return Text(
      '$_dateLabel ${review.createdAt.toString().substring(0, 10)}',
      style: const TextStyle(fontSize: 12, color: Colors.grey),
    );
  }
}
