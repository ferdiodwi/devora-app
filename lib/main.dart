import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const DevoraApp());
}

class DevoraApp extends StatefulWidget {
  const DevoraApp({super.key});

  @override
  State<DevoraApp> createState() => _DevoraAppState();
}

class _DevoraAppState extends State<DevoraApp> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    setState(() {
      _isAuthenticated = token != null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Devora Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _isLoading 
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : _isAuthenticated ? const HomeScreen() : const LoginScreen(),
    );
  }
}
