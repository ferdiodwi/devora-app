import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Hanya membaca dari file .env. URL gagal dimuat jika terjadi masalah dengan file .env
  static String get baseUrl => dotenv.env['API_URL'] ?? '';

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
      Uri.parse('$baseUrl/auth/me'), 
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

  static Future<Map<String, dynamic>> getEbooks(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ebooks/search?q=$query'),
      headers: await _getHeaders(),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  // --- CHATBOT --- //

  static Future<Map<String, dynamic>> getConversations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/chatbot/conversations'),
      headers: await _getHeaders(),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> createConversation() async {
    final response = await http.post(
      Uri.parse('$baseUrl/chatbot/conversations'),
      headers: await _getHeaders(),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> deleteConversation(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/chatbot/conversations/$id'),
      headers: await _getHeaders(),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> getMessages(int conversationId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chatbot/conversations/$conversationId/messages'),
      headers: await _getHeaders(),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> sendChatMessage(int conversationId, String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chatbot/send'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'conversation_id': conversationId,
        'message': message,
      }),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }
}
