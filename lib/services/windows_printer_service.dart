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
    /// ==============================
    /// 1️⃣ VALIDASI PRINTER ADA DI WINDOWS
    /// ==============================
    final checkResult = await Process.run(
      'powershell',
      [
        '-Command',
        'Get-Printer -Name "$printerName" | Select Name | ConvertTo-Json'
      ],
    );

    if (checkResult.stdout.toString().isEmpty) {
      throw Exception("Printer tidak ditemukan di Windows");
    }

    /// ==============================
    /// 2️⃣ GENERATE ESC/POS BYTES
    /// ==============================
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    List<int> bytes = [];

    bytes += generator.reset();

    /// ===== HEADER (SUDAH DIKIRIM DARI PARAMETER) =====
    bytes += generator.text(
      headerText,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
      ),
    );

    bytes += generator.hr();

    /// ===== SPLIT BODY BERDASARKAN MARKER =====
    const qrMarker = '[  QR CODE  ]';
    final parts = bodyText.split(qrMarker);

    /// ===== BAGIAN ATAS =====
    bytes += generator.text(
      parts.first,
      styles: const PosStyles(
        align: PosAlign.left,
      ),
    );

    /// ===== QR DI POSISI MARKER =====
    bytes += generator.feed(1);

    bytes += generator.qrcode(
      qrData,
      align: PosAlign.center,
      size: QRSize.Size8, // ukuran terbesar
    );

    bytes += generator.feed(1);

    /// ===== BAGIAN BAWAH (JIKA ADA) =====
    if (parts.length > 1) {
      bytes += generator.text(
        parts.last,
        styles: const PosStyles(
          align: PosAlign.left,
        ),
      );
    }

    bytes += generator.feed(2);
    bytes += generator.cut();

    /// ==============================
    /// 3️⃣ SIMPAN FILE TEMP
    /// ==============================
    final file = File('${Directory.systemTemp.path}\\voucher.bin');
    await file.writeAsBytes(Uint8List.fromList(bytes));

    if (!await file.exists()) {
      throw Exception("Gagal membuat file print");
    }

    /// ==============================
    /// 4️⃣ COPY RAW KE PRINTER (REAL VALIDATION)
    /// ==============================
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
      throw Exception("Printer tidak terhubung / USB terlepas");
    }
  }
}
