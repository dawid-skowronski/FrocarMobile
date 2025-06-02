import 'package:flutter/material.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/widgets/custom_app_bar.dart';

const String _ratingRequiredMessage = 'Proszę wybrać ocenę, zanim dodasz opinię.';
const String _submissionSuccessMessage = 'Dziękujemy za opinię!';
const String _submissionErrorMessage = 'Nie udało się dodać opinii. Spróbuj ponownie później.';
const String _addReviewTitle = "Dodaj opinię";
const String _howWouldYouRateService = 'Jak oceniasz tę usługę?';
const String _commentOptional = 'Komentarz (opcjonalnie)';
const String _commentHint = 'Opisz swoje wrażenia...';
const String _sendReviewButtonText = 'Wyślij opinię';

class AddReviewPage extends StatefulWidget {
  final int carRentalId;
  final int carListingId;
  final ApiService? apiService;

  const AddReviewPage({
    super.key,
    required this.carRentalId,
    required this.carListingId,
    this.apiService,
  });

  @override
  _AddReviewPageState createState() => _AddReviewPageState();
}

class _AddReviewPageState extends State<AddReviewPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
  }

  @override
  void dispose() {
    _commentController.dispose();
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

  bool _isRatingValid() {
    if (_currentRating == 0) {
      _showSnackBar(_ratingRequiredMessage, Colors.redAccent);
      return false;
    }
    return true;
  }

  void _setLoadingState(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  void _navigateBack() {
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _submitReview() async {
    if (!_isRatingValid() || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    _setLoadingState(true);

    try {
      final String? comment = _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim();

      await _apiService.addReview(
        widget.carRentalId,
        _currentRating,
        comment,
      );

      _showSnackBar(_submissionSuccessMessage, Colors.green);
      _navigateBack();
    } catch (e) {
      _showSnackBar(_submissionErrorMessage, Colors.redAccent);
      debugPrint('Błąd podczas wysyłania opinii: $e');
    } finally {
      _setLoadingState(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Color(0xFF375534);

    return Scaffold(
      appBar: CustomAppBar(
        title: _addReviewTitle,
        onNotificationPressed: () {
          Navigator.pushNamed(context, '/notifications');
        },
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : _buildReviewForm(themeColor),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildReviewForm(Color themeColor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            _buildRatingSection(),
            const SizedBox(height: 24),
            _buildCommentSection(),
            const SizedBox(height: 32),
            _buildSubmitButton(themeColor),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          _howWouldYouRateService,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < _currentRating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 32,
              ),
              onPressed: () {
                setState(() {
                  _currentRating = index + 1;
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          _commentOptional,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _commentController,
          decoration: InputDecoration(
            hintText: _commentHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLines: 5,
        ),
      ],
    );
  }

  Widget _buildSubmitButton(Color themeColor) {
    return Center(
      child: ElevatedButton(
        onPressed: _submitReview,
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          _sendReviewButtonText,
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}
