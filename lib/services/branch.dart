import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class BranchService {
  static String get baseUrl => dotenv.env['API']!;
  static String get branchCode => dotenv.env['BRANCH_CODE']!;

  static Future<double> getBranchSpend() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/branches/$branchCode'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load branch config');
    }

    final body = jsonDecode(response.body);
    final data = body['data'];

    return (data['branchSpend'] ?? 0).toDouble();
  }
}
