import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // Import your login screen widget

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(), // Open the login screen first
    );
  }
}
