import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
import '../models/voucher_claim.dart';

class VoucherClaimApiException implements Exception {
  final int statusCode;
  final String message;

  VoucherClaimApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => message;
}

class VoucherClaimService {
  static String get baseUrl => dotenv.env['API']!;

  static Future<void> sendTransaction(TransactionModel transaction) async {
    final payload = transaction.toMongoPayload();

    final response = await http.post(
      Uri.parse('$baseUrl/api/voucher-claims'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      String errorMessage = 'Request failed (${response.statusCode})';

      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body['message'] != null) {
          errorMessage = body['message'].toString();
        }
      } catch (_) {
        if (response.body.isNotEmpty) {
          errorMessage = response.body;
        }
      }

      throw VoucherClaimApiException(
        statusCode: response.statusCode,
        message: errorMessage,
      );
    }
  }

  static Future<Map<String, VoucherClaim>> fetchClaimStatusMap() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/voucher-claims'),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load voucher claims');
    }

    final body = jsonDecode(res.body);
    final List data = body['data'];

    final Map<String, VoucherClaim> map = {};

    for (final e in data) {
      final claim = VoucherClaim.fromJson(e);
      map[claim.key] = claim;
    }

    return map;
  }

  static Future<void> logPrint({
    required int isId,
    required String branchCode,
    required String printedBy,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/voucher-claims/print'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "isId": isId,
        "branchCode": branchCode,
        "printedBy": printedBy,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(body['message'] ?? 'Print limit reached');
    }
  }
}
