import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';
import 'pages/login.dart';
import 'package:flutter/gestures.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager
  await windowManager.ensureInitialized();

  const WindowOptions windowOptions = WindowOptions(
    center: true,
    backgroundColor: Colors.white,
    title: "Voucher Claim",
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.maximize(); // <-- FULLSCREEN
    await windowManager.focus();
  });

  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voucher Claim',
      debugShowCheckedModeBanner: false,

      // ✅ SMOOTH DESKTOP SCROLL
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.trackpad,
        },
      ),

      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginPage(),
      },
    );
  }
}
