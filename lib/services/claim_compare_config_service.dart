import 'package:shared_preferences/shared_preferences.dart';

class ClaimCompareConfigService {
  static const _key = 'claim_compare_basis';
  static const total = 'total';
  static const subtotal = 'subtotal';

  static Future<void> saveBasis(String basis) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = (basis == subtotal) ? subtotal : total;
    await prefs.setString(_key, normalized);
  }

  static Future<String> getBasis() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == subtotal) return subtotal;
    return total;
  }
}
