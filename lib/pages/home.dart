import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voucher_claim/models/voucher_claim.dart';
import 'package:voucher_claim/pages/printer_settings_page.dart';
import 'package:voucher_claim/services/branch.dart';
import '../services/transactions.dart';
import '../services/voucher_claim.dart';
import '../models/transaction.dart';
import '../components/pagination.dart';
import 'qr_page.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> agent;

  const HomePage({super.key, required this.agent});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color color;

    switch (status) {
      case 'Read':
        color = Colors.blue;
        break;
      case 'Delivered':
        color = Colors.green;
        break;
      case 'Draft':
        color = Colors.orange;
        break;
      default:
        color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HomePageState extends State<HomePage> {
  final repo = TransactionRepository();
  final rupiah = NumberFormat("#,##0", "id_ID");
  final dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');
  bool get isAdmin => widget.agent['role'] == 'admin';

  Map<String, VoucherClaim> claimMap = {};

  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool isLoading = true;
  String? errorText;

  String getClaimStatus(TransactionModel t) {
    final claim = claimMap['${t.isId}-${t.branchCode}'];
    return claim?.status ?? 'Not Claimed';
  }

  int getPrintCount(TransactionModel t) {
    final claim = claimMap['${t.isId}-${t.branchCode}'];
    return claim?.printCount ?? 0;
  }

  String selectedStatus = 'All';

  final List<String> statusOptions = [
    'All',
    'Not Claimed',
    'Claimed',
    'Draft',
    'Delivered',
    'Read',
  ];

  List<TransactionModel> transactions = [];
  TransactionModel? selectedTransaction;
  int rowsPerPage = 10;
  int currentPage = 0;

  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  List<TransactionModel> filteredTransactions = [];

  List<TransactionModel> get paginatedData {
    final start = currentPage * rowsPerPage;
    final end = (currentPage + 1) * rowsPerPage;
    final list = filteredTransactions;

    if (start >= list.length) return [];

    return list.sublist(
      start,
      end > list.length ? list.length : end,
    );
  }

  void _applyFilters() {
    setState(() {
      filteredTransactions = transactions.where((t) {
        final status = getClaimStatus(t);

        final matchesSearch =
            t.counter.toString().toLowerCase().contains(searchQuery) ||
                t.areaName.toLowerCase().contains(searchQuery) ||
                t.tableName.toLowerCase().contains(searchQuery);

        final matchesStatus =
            selectedStatus == 'All' || status == selectedStatus;

        return matchesSearch && matchesStatus;
      }).toList();

      currentPage = 0;
    });
  }

  @override
  void initState() {
    super.initState();

    _loadTransactions();

    Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _loadTransactions(silent: true);
      }
    });
  }

  Future<void> _loadTransactions({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoading = true;
        errorText = null;
      });
    }

    try {
      final branchSpend = await BranchService.getBranchSpend();

      final currentSelectedId = selectedTransaction?.isId;
      final currentBranchCode = selectedTransaction?.branchCode;

      final results = await Future.wait([
        repo.getTransactionsByDate(branchSpend, selectedDate),
        VoucherClaimService.fetchClaimStatusMap(),
      ]);

      final trx = results[0] as List<TransactionModel>;
      final claimMapResult = results[1] as Map<String, VoucherClaim>;

      if (!mounted) return;

      setState(() {
        transactions = trx;
        claimMap = claimMapResult;

        if (!silent) {
          searchQuery = '';
          selectedStatus = 'All';
        }

        _applyFilters();

        if (trx.isEmpty) {
          selectedTransaction = null;
        } else if (currentSelectedId != null) {
          final existing = trx.where((t) =>
              t.isId == currentSelectedId && t.branchCode == currentBranchCode);

          selectedTransaction =
              existing.isNotEmpty ? existing.first : trx.first;
        } else {
          selectedTransaction = trx.first;
        }
      });
    } catch (e) {
      if (!mounted) return;

      if (!silent) {
        setState(() => errorText = e.toString());
      }
    } finally {
      if (!mounted) return;

      if (!silent) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> pickDate() async {
    final today = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(selectedDate),

      /// 🔥 INI YANG DIUBAH
      firstDate: isAdmin
          ? DateTime(2000) // bebas (atau DateTime(1970))
          : today.subtract(const Duration(days: 7)),

      lastDate: isAdmin
          ? DateTime(2100) // bebas ke depan
          : today,
    );

    if (picked != null) {
      setState(() {
        selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
      _loadTransactions();
    }
  }

  String get printedBy => widget.agent['name'] ?? 'Unknown';
  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.parse(selectedDate));

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Voucher Claim'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PrinterSettingsPage(),
                ),
              );
            },
          ),

          const SizedBox(width: 16),

          /// ===== AGENT NAME =====
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, size: 16),
                const SizedBox(width: 6),
                Text(
                  printedBy,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          /// ===== LOGOUT BUTTON =====
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text(
              "Logout",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// === FILTER BAR ===
            Row(
              children: [
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      searchQuery = val.toLowerCase();
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 220,
                  child: TextField(
                    readOnly: true,
                    controller: TextEditingController(text: formattedDate),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    onTap: pickDate,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    items: statusOptions.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedStatus = val!;
                      });
                      _applyFilters();
                    },
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _loadTransactions,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh"),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// === MAIN CONTENT ===
            Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorText != null
                        ? Center(
                            child: Text(
                              errorText!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        : transactions.isEmpty
                            ? _buildEmptyState()
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5, // ← LEBIH BESAR
                                    child: _buildTableCard(),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2, // ← LEBIH KECIL
                                    child: selectedTransaction == null
                                        ? const SizedBox()
                                        : QrPreviewCard(
                                            transaction: selectedTransaction!,
                                            claimStatus: getClaimStatus(
                                                selectedTransaction!),
                                            printCount: getPrintCount(
                                                selectedTransaction!),
                                            printedBy: printedBy,
                                            onSuccess: _loadTransactions,
                                          ),
                                  ),
                                ],
                              )),

            if (!isLoading && transactions.isNotEmpty)
              TablePaginationFooter(
                rowsPerPage: rowsPerPage,
                currentPage: currentPage,
                totalItems: filteredTransactions.length,
                onRowsPerPageChanged: (val) {
                  setState(() {
                    rowsPerPage = val;
                    currentPage = 0;
                  });
                },
                onPageChanged: (page) {
                  setState(() => currentPage = page);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical, // ⬅️ TAMBAH VERTICAL
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                showCheckboxColumn: false,
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade300),
                columnSpacing: 32,
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Transaction')),
                  DataColumn(label: Text('Transaction Date')),
                  DataColumn(label: Text('Area')),
                  DataColumn(label: Text('Table')),
                  DataColumn(label: Text('Subtotal')),
                  DataColumn(label: Text('Total')),
                  DataColumn(label: Text('Status')),
                ],
                rows: paginatedData.map((t) {
                  return DataRow(
                    selected: selectedTransaction == t,
                    onSelectChanged: (_) {
                      setState(() => selectedTransaction = t);
                    },
                    cells: [
                      DataCell(
                          SizedBox(width: 50, child: Text(t.isId.toString()))),
                      DataCell(SizedBox(
                          width: 50, child: Text(t.counter.toString()))),
                      DataCell(SizedBox(
                          width: 120,
                          child: Text(
                              dateTimeFormatter.format(t.isTransactionTime)))),
                      DataCell(SizedBox(width: 100, child: Text(t.areaName))),
                      DataCell(SizedBox(width: 40, child: Text(t.tableName))),
                      DataCell(SizedBox(
                          width: 100,
                          child:
                              Text("Rp ${rupiah.format(t.totalBeforeDisc)}"))),
                      DataCell(SizedBox(
                          width: 100,
                          child: Text("Rp ${rupiah.format(t.totalSpent)}"))),
                      DataCell(
                        SizedBox(
                          width: 110,
                          child: _StatusBadge(status: getClaimStatus(t)),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildEmptyState() {
  return const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.receipt_long_outlined,
          size: 64,
          color: Colors.grey,
        ),
        SizedBox(height: 16),
        Text(
          'Data tidak ditemukan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Tidak ada voucher claim\npada tanggal yang dipilih',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    ),
  );
}
