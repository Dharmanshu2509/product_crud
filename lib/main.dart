import 'package:flutter/material.dart';
import 'package:product_crud/home_page.dart';
import 'package:product_crud/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
       initialRoute: '/',
      routes: {
        '/': (context) => FutureBuilder<bool>(
              future: _isLoggedIn(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasData && snapshot.data!) {
                  return const HomePage();  // Navigate to HomePage if logged in
                } else {
                  return const LoginPage();  // Navigate to LoginPage if not logged in
                }
              },
            ),
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }

  // Method to check if the user is logged in
  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }
}