import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/claim_compare_config_service.dart';
import '../services/printer_config_service.dart';
import '../services/windows_printer_service.dart';

class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class PrinterInfo {
  final String name;
  final String status;

  PrinterInfo(this.name, this.status);
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  List<PrinterInfo> printers = [];
  String? selectedPrinter;
  String selectedCompareBasis = ClaimCompareConfigService.total;
  bool isLoading = true;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadPrinters();
    await _loadSavedPrinter();
    await _loadSavedCompareBasis();

    // Auto refresh setiap 3 detik agar status printer cepat terupdate.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _loadPrinters(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedPrinter() async {
    final saved = await PrinterConfigService.getPrinter();

    if (saved != null && printers.any((p) => p.name == saved)) {
      setState(() => selectedPrinter = saved);
    } else {
      setState(() => selectedPrinter = null);
    }
  }

  Future<void> _loadSavedCompareBasis() async {
    final saved = await ClaimCompareConfigService.getBasis();
    setState(() => selectedCompareBasis = saved);
  }

  Future<void> _loadPrinters() async {
    try {
      final result = await Process.run(
        'powershell',
        [
          '-Command',
          r'Get-Printer | Select Name, PrinterStatus | ConvertTo-Json'
        ],
      );

      final jsonString = result.stdout.toString();

      if (jsonString.isEmpty) {
        setState(() {
          printers = [];
          isLoading = false;
        });
        return;
      }

      final decoded = jsonDecode(jsonString);
      List<dynamic> printersList = decoded is List ? decoded : [decoded];

      final filtered = printersList.where((printer) {
        final name = printer['Name'].toString().toLowerCase();

        if (name.contains('pdf') ||
            name.contains('xps') ||
            name.contains('onenote') ||
            name.contains('fax')) {
          return false;
        }

        return true;
      }).toList();

      final printerInfos = filtered.map<PrinterInfo>((p) {
        final statusCode = p['PrinterStatus'];

        String status;
        if (statusCode == 7) {
          status = 'Offline';
        } else {
          status = 'Online';
        }

        return PrinterInfo(p['Name'], status);
      }).toList();

      setState(() {
        printers = printerInfos;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _savePrinter() async {
    if (selectedPrinter == null) return;

    await PrinterConfigService.savePrinter(selectedPrinter!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Printer berhasil disimpan'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _testPrint() async {
    if (selectedPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih printer terlebih dahulu')),
      );
      return;
    }

    try {
      await WindowsPrinterService.printThermal(
        printerName: selectedPrinter!,
        headerText: 'THERMAL TEST',
        bodyText:
            'Test print berhasil.\nJika ini keluar berarti printer sudah benar.',
        qrData: 'https://test.com',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test print berhasil dikirim'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal print: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveCompareBasis() async {
    await ClaimCompareConfigService.saveBasis(selectedCompareBasis);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          selectedCompareBasis == ClaimCompareConfigService.subtotal
              ? 'Compare basis disimpan: Subtotal'
              : 'Compare basis disimpan: Total',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('General Settings'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1100;

                final printerSection = _buildSectionCard(
                  icon: Icons.print,
                  title: 'Printer',
                  description:
                      'Atur printer thermal default dan lakukan test print.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: printers.any((p) => p.name == selectedPrinter)
                            ? selectedPrinter
                            : null,
                        isExpanded: true,
                        items: printers.map((printer) {
                          return DropdownMenuItem(
                            value: printer.name,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    printer.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  printer.status,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: printer.status == 'Online'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => selectedPrinter = val);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Pilih Printer Thermal',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _savePrinter,
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Simpan Printer'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _testPrint,
                              icon: const Icon(Icons.play_arrow_rounded),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              label: const Text('Test Print'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                final claimSection = _buildSectionCard(
                  icon: Icons.tune,
                  title: 'Voucher Rule',
                  description:
                      'Pilih acuan compare threshold voucher untuk semua branch.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedCompareBasis,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: ClaimCompareConfigService.total,
                            child: Text('Total'),
                          ),
                          DropdownMenuItem(
                            value: ClaimCompareConfigService.subtotal,
                            child: Text('Subtotal'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() => selectedCompareBasis = val);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Compare Voucher Threshold By',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveCompareBasis,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Simpan Compare Basis'),
                        ),
                      ),
                    ],
                  ),
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1300),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: printerSection),
                              const SizedBox(width: 16),
                              Expanded(child: claimSection),
                            ],
                          )
                        : Column(
                            children: [
                              printerSection,
                              const SizedBox(height: 16),
                              claimSection,
                            ],
                          ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String description,
    required Widget child,
  }) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
