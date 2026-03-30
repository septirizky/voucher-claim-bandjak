class TransactionModel {
  final int isId;
  final String branchCode;
  final String branchName;

  final DateTime isDate;
  final DateTime isStartTime;
  final DateTime isTransactionTime;

  final int tId;
  final int taId;
  final int uId;
  final int mId;

  final double discountAmount;
  final double discountPercent;

  final double vatAmount;
  final double vatPercent;

  final double totalBeforeDisc;
  final double totalBeforeVat;

  final double cookingCharge;
  final double rounding;

  final double totalSpent;

  final double pax;
  final String name;
  final String posId;
  final int counter;
  final String areaName;
  final String tableName;

  final String status;

  TransactionModel({
    required this.isId,
    required this.branchCode,
    required this.branchName,
    required this.isDate,
    required this.isStartTime,
    required this.isTransactionTime,
    required this.tId,
    required this.taId,
    required this.uId,
    required this.mId,
    required this.discountAmount,
    required this.discountPercent,
    required this.vatAmount,
    required this.vatPercent,
    required this.totalBeforeDisc,
    required this.totalBeforeVat,
    required this.cookingCharge,
    required this.rounding,
    required this.totalSpent,
    required this.pax,
    required this.name,
    required this.posId,
    required this.counter,
    required this.areaName,
    required this.tableName,
    required this.status,
  });

  /// 🔥 INI YANG AKAN DIKIRIM KE MONGODB
  Map<String, dynamic> toMongoPayload() {
    return {
      "transaction": {
        "isId": isId,
        "branchCode": branchCode,
        "isDate": isDate.toIso8601String().split('T').first,
        "isStartTime": isStartTime.toUtc().toIso8601String(),
        "isTransactionTime": isTransactionTime.toUtc().toIso8601String(),
        "tId": tId,
        "taId": taId,
        "uId": uId,
        "mId": mId,
        "discount": {
          "amount": discountAmount,
          "percent": discountPercent,
        },
        "vat": {
          "amount": vatAmount,
          "percent": vatPercent,
        },
        "totalBeforeDisc": totalBeforeDisc,
        "totalBeforeVat": totalBeforeVat,
        "cookingCharge": cookingCharge,
        "rounding": rounding,
        "totalSpent": totalSpent,
        "pax": pax,
        "name": name,
        "posId": posId,
        "counter": counter,
        "areaName": areaName,
        "tableName": tableName,
        "status": status,
      }
    };
  }
}
