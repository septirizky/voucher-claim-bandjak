import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:esc_pos_utils/esc_pos_utils.dart';

class WindowsPrinterService {
  static Future<void> printThermal({
    required String printerName,
    required String headerText,
    required String bodyText,
    required String qrData,
  }) async {
    await _validatePrinterReady(printerName);

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    List<int> bytes = [];
    bytes += generator.reset();
    bytes += generator.text(
      headerText,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
      ),
    );
    bytes += generator.hr();

    const qrMarker = '[  QR CODE  ]';
    final parts = bodyText.split(qrMarker);

    bytes += generator.text(
      parts.first,
      styles: const PosStyles(align: PosAlign.left),
    );

    bytes += generator.feed(1);
    bytes += generator.qrcode(
      qrData,
      align: PosAlign.center,
      size: QRSize.Size8,
    );
    bytes += generator.feed(1);

    if (parts.length > 1) {
      bytes += generator.text(
        parts.last,
        styles: const PosStyles(align: PosAlign.left),
      );
    }

    bytes += generator.feed(2);
    bytes += generator.cut();

    final file = File('${Directory.systemTemp.path}\\voucher.bin');
    await file.writeAsBytes(Uint8List.fromList(bytes));

    if (!await file.exists()) {
      throw Exception('Gagal membuat file print');
    }

    final result = await Process.run(
      'cmd',
      [
        '/c',
        'copy',
        '/b',
        file.path,
        '\\\\localhost\\$printerName',
      ],
    );

    if (result.exitCode != 0) {
      throw Exception('Printer tidak terhubung / USB terlepas');
    }
  }

  static Future<void> _validatePrinterReady(String printerName) async {
    final result = await Process.run(
      'powershell',
      [
        '-Command',
        r'Get-CimInstance Win32_Printer | Select Name, WorkOffline, PrinterStatus, ExtendedPrinterStatus, DetectedErrorState, Status | ConvertTo-Json -Depth 3',
      ],
    );

    if (result.exitCode != 0) {
      throw Exception('Gagal membaca status printer Windows');
    }

    final raw = result.stdout.toString().trim();
    if (raw.isEmpty) {
      throw Exception('Printer tidak ditemukan di Windows');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw Exception('Gagal membaca data printer dari Windows');
    }

    final printers = decoded is List ? decoded : [decoded];
    dynamic target;
    for (final p in printers) {
      if (p is Map && p['Name']?.toString() == printerName) {
        target = p;
        break;
      }
    }

    if (target == null) {
      throw Exception('Printer tidak ditemukan di Windows');
    }

    final isWorkOffline = target['WorkOffline'] == true ||
        target['WorkOffline']?.toString().toLowerCase() == 'true';
    final statusCode = int.tryParse(target['PrinterStatus']?.toString() ?? '');
    final extendedStatusCode =
        int.tryParse(target['ExtendedPrinterStatus']?.toString() ?? '');
    final detectedErrorStateCode =
        int.tryParse(target['DetectedErrorState']?.toString() ?? '');
    final statusText = target['Status']?.toString().toLowerCase() ?? '';
    final printerStatusText =
        target['PrinterStatus']?.toString().toLowerCase() ?? '';

    final isOffline = isWorkOffline ||
        statusCode == 7 ||
        extendedStatusCode == 7 ||
        statusText.contains('offline') ||
        printerStatusText.contains('offline') ||
        (detectedErrorStateCode != null && detectedErrorStateCode != 0);

    if (isOffline) {
      throw Exception('Printer sedang offline. Print dibatalkan.');
    }
  }
}
