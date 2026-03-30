class BranchConfig {
  final String branchCode;
  final double branchSpend;

  BranchConfig({
    required this.branchCode,
    required this.branchSpend,
  });

  factory BranchConfig.fromJson(Map<String, dynamic> json) {
    return BranchConfig(
      branchCode: json['branchCode'],
      branchSpend: (json['branchSpend'] ?? 0).toDouble(),
    );
  }
}
