import 'package:flutter/material.dart';
import 'package:currency_converter/currency_converter_page.dart';

void main() {
  runApp(const MyApp());
}

// widget
//1. StatelessWidget(immutable)    ||    2. StatefulWidget(mutable)
// video: 12:50:00

// two types of design are there

//1. Material design          ||   2. Cupertino Design

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: CurrencyConverterPage());
  }
}
