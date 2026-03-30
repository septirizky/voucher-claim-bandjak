import '../models/transaction.dart';
import '../config/db.dart';

class TransactionRepository {
  Future<List<TransactionModel>> getTransactionsByDate(
    double minSpend,
    String date,
  ) async {
    final conn = await MySqlService.connect();

    try {
      final results = await conn.query('''
        SELECT
          s.is_id,
          b.br_code,
          b.br_name,

          s.is_date,
          s.is_start_time,
          s.is_transaction_time,

          s.t_id,
          s.ta_id,

          ta.ta_name AS area_name,
          t.t_name  AS table_name,

          s.u_id,
          s.m_id,

          s.is_discount_amount,
          s.is_discount_percent,
          s.is_vat_amount,
          s.is_vat_percent,

          s.is_total_before_disc,
          s.is_total_before_vat,
          s.is_cooking_charge,
          s.is_rounding,
          s.is_total,

          s.is_pax,
          s.is_name,
          s.is_pos_id,
          s.is_counter,
          s.is_status
        FROM item_sale s
        JOIN branch b ON b.br_id = s.br_id
        LEFT JOIN tables_area ta ON ta.ta_id = s.ta_id
        LEFT JOIN tables t ON t.t_id = s.t_id
        WHERE s.is_total > ?
          AND s.is_date = ?
          AND s.is_status = 'Active'
        ORDER BY s.is_id DESC
      ''', [minSpend, date]);

      return results.map((r) {
        return TransactionModel(
          isId: r['is_id'],
          branchCode: r['br_code'],
          branchName: r['br_name'] ?? '',
          isDate: r['is_date'],
          isStartTime: r['is_start_time'],
          isTransactionTime: r['is_transaction_time'],
          tId: r['t_id'],
          taId: r['ta_id'],
          uId: r['u_id'],
          mId: r['m_id'] ?? 0,
          discountAmount: (r['is_discount_amount'] ?? 0).toDouble(),
          discountPercent: (r['is_discount_percent'] ?? 0).toDouble(),
          vatAmount: (r['is_vat_amount'] ?? 0).toDouble(),
          vatPercent: (r['is_vat_percent'] ?? 0).toDouble(),
          totalBeforeDisc: (r['is_total_before_disc'] ?? 0).toDouble(),
          totalBeforeVat: (r['is_total_before_vat'] ?? 0).toDouble(),
          cookingCharge: (r['is_cooking_charge'] ?? 0).toDouble(),
          rounding: (r['is_rounding'] ?? 0).toDouble(),
          totalSpent: (r['is_total'] ?? 0).toDouble(),
          pax: (r['is_pax'] ?? 0).toDouble(),
          name: r['is_name'] ?? '',
          posId: r['is_pos_id'] ?? '',
          counter: r['is_counter'] ?? r['is_id'],
          areaName: r['area_name'] ?? '-',
          tableName: r['table_name'] ?? '-',
          status: r['is_status'] ?? 'Active',
        );
      }).toList();
    } finally {
      await conn.close();
    }
  }

  /// OPTIONAL: biar backward compatible
  Future<List<TransactionModel>> getTransactionsToday(
    double minSpend,
  ) async {
    final today = DateTime.now();
    final date =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    return getTransactionsByDate(minSpend, date);
  }
}
