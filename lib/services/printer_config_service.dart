import 'package:shared_preferences/shared_preferences.dart';

class PrinterConfigService {
  static const _key = 'default_printer';

  static Future<void> savePrinter(String printerName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, printerName);
  }

  static Future<String?> getPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
