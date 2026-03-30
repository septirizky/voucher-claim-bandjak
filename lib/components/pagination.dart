import 'package:flutter/material.dart';

class TablePaginationFooter extends StatelessWidget {
  final int rowsPerPage;
  final int currentPage;
  final int totalItems;
  final Function(int) onRowsPerPageChanged;
  final Function(int) onPageChanged;

  const TablePaginationFooter({
    super.key,
    required this.rowsPerPage,
    required this.currentPage,
    required this.totalItems,
    required this.onRowsPerPageChanged,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = (totalItems / rowsPerPage).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Text("Rows per page"),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: rowsPerPage,
            items: const [10, 20, 50].map((e) {
              return DropdownMenuItem(value: e, child: Text(e.toString()));
            }).toList(),
            onChanged: (val) => onRowsPerPageChanged(val!),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed:
                currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
          ),
          Text("${currentPage + 1} / $totalPages"),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages - 1
                ? () => onPageChanged(currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
