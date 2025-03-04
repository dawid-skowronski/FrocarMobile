import 'package:flutter/material.dart';
import 'package:test_project/widgets/custom_app_bar.dart';

class RentCarPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "FroCar"),
      body: Center(
        child: Text(
          "Tutaj możesz wynająć samochód",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
