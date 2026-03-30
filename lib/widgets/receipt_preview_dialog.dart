import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:voucher_claim/services/printer_config_service.dart';
import 'package:voucher_claim/services/voucher_claim.dart';
import '../models/transaction.dart';
import '../utils/receipt_preview.dart';
import '../services/windows_printer_service.dart';

class ReceiptPreviewDialog {
  static void show(
    BuildContext context,
    TransactionModel t,
    String printedBy, {
    required VoidCallback onPrinted,
  }) {
    final receipt = ReceiptPreview.build(t, printedBy);
    final parts = receipt.split(ReceiptPreview.qrMarker);

    final url = '${dotenv.env['URL']}/claim/${t.isId}/${t.branchCode}/${t.tId}';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Preview Struk'),
        content: SizedBox(
          width: 280,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parts.first,
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: QrImageView(
                    data: url,
                    size: 160,
                  ),
                ),
                const SizedBox(height: 16),
                if (parts.length > 1)
                  Text(
                    parts.last,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5CB3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () async {
                    final printerName = await PrinterConfigService.getPrinter();

                    if (printerName == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Printer belum dikonfigurasi")),
                      );
                      return;
                    }

                    try {
                      final restaurant =
                          (t.branchCode == 'PS' || t.branchCode == 'BTR')
                              ? 'PESISIR SEAFOOD'
                              : 'BANDAR DJAKARTA';

                      await VoucherClaimService.logPrint(
                        isId: t.isId,
                        branchCode: t.branchCode,
                        printedBy: printedBy,
                      );

                      await WindowsPrinterService.printThermal(
                        printerName: printerName,
                        headerText: "$restaurant\n${t.branchName}",
                        bodyText: receipt,
                        qrData: url,
                      );

                      Navigator.pop(context);
                      onPrinted();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Print berhasil"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('PRINT'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
