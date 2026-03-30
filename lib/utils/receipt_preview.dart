import 'package:intl/intl.dart';
import '../models/transaction.dart';

class ReceiptPreview {
  static const qrMarker = '[  QR CODE  ]';

  static String build(TransactionModel t, String printedBy) {
    final rupiah = NumberFormat("#,##0", "id_ID");

    /// 🔥 FORMAT TANGGAL & JAM
    final tanggalFormatter = DateFormat('dd-MM-yyyy');
    final jamFormatter = DateFormat('HH:mm');

    final tanggal = tanggalFormatter.format(t.isTransactionTime);
    final jam = jamFormatter.format(t.isTransactionTime);

    /// 🔥 FORMAT PRINT TIME
    final printTimeFormatter = DateFormat('dd-MM-yyyy HH:mm');
    final printTime = printTimeFormatter.format(DateTime.now());

    final buffer = StringBuffer();

    buffer.writeln('PROGRAM CASHBACK VOUCHER');
    buffer.writeln('');
    buffer
        .writeln('Transaksi Anda berkesempatan mendapatkan voucher cashback.');
    buffer.writeln('');

    buffer.writeln('No. Transaksi : ${t.counter}');
    buffer.writeln('Tanggal       : $tanggal');
    buffer.writeln('Jam           : $jam');
    buffer.writeln('Total         : Rp. ${rupiah.format(t.totalSpent)}');
    buffer.writeln('Printed By    : $printedBy');
    buffer.writeln('Printed Time  : $printTime');

    buffer.writeln('');
    buffer.writeln('CARA KLAIM:');
    buffer.writeln('1. Scan QR Code di bawah');
    buffer.writeln('2. Isi form singkat');
    buffer.writeln('3. Voucher dikirim via WhatsApp');
    buffer.writeln('');
    buffer.writeln('CATATAN:');
    buffer.writeln('Voucher digunakan pada pembelanjaan berikutnya.');
    buffer.writeln(qrMarker);
    buffer.writeln('================================');
    buffer.writeln('Terima kasih atas kunjungan Anda');
    buffer.writeln('================================');

    return buffer.toString();
  }
}
