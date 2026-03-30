class VoucherClaim {
  final int isId;
  final String branchCode;
  final String status;
  final int printCount;

  VoucherClaim({
    required this.isId,
    required this.branchCode,
    required this.status,
    required this.printCount,
  });

  factory VoucherClaim.fromJson(Map<String, dynamic> json) {
    final trx = json['transaction'];

    return VoucherClaim(
      isId: trx['isId'],
      branchCode: trx['branchCode'],
      status: json['status'],
      printCount: json['printCount'] ?? 0,
    );
  }

  String get key => '$isId-$branchCode';
}
