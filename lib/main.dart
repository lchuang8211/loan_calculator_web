import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() => runApp(const FinancialCalculatorApp());

class FinancialCalculatorApp extends StatelessWidget {
  const FinancialCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '財務計算工具',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
