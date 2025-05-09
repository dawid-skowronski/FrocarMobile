import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/car_rental_review.dart';
import '../widgets/custom_app_bar.dart';

class CarReviewsPage extends StatelessWidget {
  final int listingId;

  const CarReviewsPage({super.key, required this.listingId});

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Color(0xFF375534);
    final ApiService apiService = ApiService();

    return Scaffold(
      appBar: const CustomAppBar(title: "Recenzje pojazdu"),
      body: FutureBuilder<List<CarRentalReview>>(
        future: apiService.getReviewsForListing(listingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Błąd podczas pobierania recenzji',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final reviews = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
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
                        Row(
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
                            Text(
                              'Autor: ${review.user.username}',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          review.comment ?? 'Brak komentarza',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Data: ${review.createdAt.toString().substring(0, 10)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(
              child: Text(
                'Brak recenzji dla tego pojazdu.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
        },
      ),
    );
  }
}