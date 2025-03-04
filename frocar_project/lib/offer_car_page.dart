import 'package:flutter/material.dart';
import 'package:test_project/widgets/custom_app_bar.dart';

class OfferCarPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "FroCar"),
      body: Center(
        child: Text(
          "Tutaj możesz oddać samochód na wynajem",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
