import 'package:mysql1/mysql1.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MySqlService {
  static Future<MySqlConnection> connect() async {
    final settings = ConnectionSettings(
      host: dotenv.env['DB_HOST']!,
      port: int.parse(dotenv.env['DB_PORT']!),
      user: dotenv.env['DB_USER']!,
      password: dotenv.env['DB_PASSWORD']!,
      db: dotenv.env['DB_NAME']!,
    );

    return MySqlConnection.connect(settings);
  }
}
