import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Ganti dengan IP lokal emulator atau IP server jika dites ke physical device
  // Emulator Android = 10.0.2.2. Gunakan /api/v1/ prefix API
  static const String baseUrl = 'http://192.168.0.38:8000/api/v1';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<void> _saveToken(Map<String, dynamic> responseData) async {
    if (responseData.containsKey('access_token')) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', responseData['access_token']);
    }
  }

  // --- AUTH --- //

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await _saveToken(data);
    }
    return {'status': response.statusCode, 'data': data};
  }

  static Future<Map<String, dynamic>> register(
      String name, String email, String phone, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      await _saveToken(data);
    }
    return {'status': response.statusCode, 'data': data};
  }

  static Future<void> logout() async {
    await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: await _getHeaders(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // --- CLAIM ACCOUNT --- //

  static Future<Map<String, dynamic>> claimLookup(String nisNip) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/claim-lookup'),
      headers: await _getHeaders(),
      body: jsonEncode({'nis_nip': nisNip}),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> claimActivate({
    required int memberId,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/claim-activate'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'member_id': memberId,
        'email': email,
        'password': password,
        'password_confirmation': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await _saveToken(data);
    }
    return {'status': response.statusCode, 'data': data};
  }
  // --- APP FEATURES --- //

  static Future<Map<String, dynamic>> getBooks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/books'),
      headers: await _getHeaders(),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/member/profile'), 
      headers: await _getHeaders(),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> getLoans() async {
    final response = await http.get(
      Uri.parse('$baseUrl/loans'),
      headers: await _getHeaders(),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }
}
