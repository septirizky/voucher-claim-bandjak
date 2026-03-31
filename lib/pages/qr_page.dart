import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:voucher_claim/widgets/receipt_preview_dialog.dart';
import '../models/transaction.dart';
import '../services/voucher_claim.dart';

class QrPreviewCard extends StatefulWidget {
  final TransactionModel transaction;
  final String claimStatus;
  final int printCount;
  final String printedBy;
  final VoidCallback onSuccess;

  const QrPreviewCard({
    super.key,
    required this.transaction,
    required this.claimStatus,
    required this.printCount,
    required this.printedBy,
    required this.onSuccess,
  });

  @override
  State<QrPreviewCard> createState() => _QrPreviewCardState();
}

class _QrPreviewCardState extends State<QrPreviewCard> {
  bool isSending = false;

  final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

  bool get isAlreadySent => widget.claimStatus != 'Not Claimed';

  String getRestaurantName(String brCode) {
    if (brCode == 'PS' || brCode == 'BTR') {
      return 'PESISIR SEAFOOD';
    }
    return 'BANDAR DJAKARTA';
  }

  String get printButtonLabel {
    if (!isAlreadySent) return "SEND";

    if (widget.printCount == 0) return "PRINT";
    if (widget.printCount == 1) return "REPRINT";
    if (widget.printCount == 2) return "LAST PRINT";

    return "PRINT LIMIT";
  }

  Color get printButtonColor {
    if (!isAlreadySent) {
      return const Color(0xFF2E7D32); // SEND (hijau)
    }

    if (widget.printCount == 0) {
      return const Color(0xFF1E5CB3); // PRINT (biru)
    }

    if (widget.printCount == 1) {
      return Colors.orange; // REPRINT (kuning warning)
    }

    if (widget.printCount == 2) {
      return Colors.red; // LAST PRINT
    }

    return Colors.grey;
  }

  String get printInfo {
    if (!isAlreadySent) return "";

    final next = widget.printCount >= 3 ? 3 : widget.printCount + 1;

    return "Print $next of 3";
  }

  bool get isPrintDisabled {
    return widget.claimStatus == 'Read' ||
        widget.claimStatus == 'Delivered' ||
        widget.claimStatus == 'Sent' ||
        widget.printCount >= 3;
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final url = '${dotenv.env['URL']}/claim/${t.isId}/${t.branchCode}/${t.tId}';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// ===== HEADER =====
            Text(
              getRestaurantName(t.branchCode),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              t.branchName.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 1.5,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 12),
            const Divider(),

            /// ===== INFO =====
            _infoRow('No. Transaksi', t.counter.toString()),
            _infoRow(
              'Tanggal',
              dateFormatter.format(t.isTransactionTime),
            ),
            _infoRow(
              'Subtotal',
              'Rp ${NumberFormat("#,##0", "id_ID").format(t.totalBeforeDisc)}',
            ),
            if (t.discountAmount != 0)
              _infoRow(
                'Diskon',
                'Rp ${NumberFormat("#,##0", "id_ID").format(t.discountAmount)}',
              ),
            _infoRow(
              'PB1',
              'Rp ${NumberFormat("#,##0", "id_ID").format(t.vatAmount)}',
            ),
            _infoRow(
              'Total',
              'Rp ${NumberFormat("#,##0", "id_ID").format(t.totalSpent)}',
            ),

            const SizedBox(height: 12),
            const Divider(),

            /// ===== QR =====
            const SizedBox(height: 12),
            Flexible(
              child: QrImageView(
                data: url,
                size: 180,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'SCAN QR CODE',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            /// ===== BUTTON SEND / PRINT =====
            /// ===== BUTTON SEND / PRINT =====
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isPrintDisabled ? Colors.grey : printButtonColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isSending || isPrintDisabled
                        ? null
                        : () async {
                            if (isAlreadySent) {
                              ReceiptPreviewDialog.show(
                                context,
                                t,
                                widget.printedBy,
                                onPrinted: widget.onSuccess,
                              );
                              return;
                            }

                            /// ===== MODE SEND =====
                            setState(() => isSending = true);

                            try {
                              await VoucherClaimService.sendTransaction(t);

                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Berhasil dikirim ke server'),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              widget.onSuccess();
                            } catch (e) {
                              final apiError = e is VoucherClaimApiException
                                  ? e
                                  : null;
                              final errorMessage = apiError?.message ??
                                  e.toString().replaceFirst('Exception: ', '');

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: apiError?.statusCode == 409
                                      ? Colors.orange
                                      : Colors.red,
                                ),
                              );

                              if (apiError?.statusCode == 409) {
                                widget.onSuccess();
                              }
                            } finally {
                              if (mounted) {
                                setState(() => isSending = false);
                              }
                            }
                          },
                    child: isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            printButtonLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                if (isAlreadySent)
                  Text(
                    widget.printCount == 0
                        ? "Belum pernah print"
                        : widget.printCount >= 3
                            ? "Maximum print reached"
                            : "Print ${widget.printCount} of 3",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
