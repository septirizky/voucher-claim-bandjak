import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static String get baseUrl => dotenv.env['API']!;

  static Future<Map<String, dynamic>> login(String pin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/agents/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"pin": pin}),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['error'] ?? 'Login failed');
    }

    return body['data'];
  }
}
