import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
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

    /// 🔥 AUTO REFRESH tiap 3 detik (auto reconnect USB)
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

        // hide virtual
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
          status = "Offline";
        } else {
          status = "Online";
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Printer berhasil disimpan"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _testPrint() async {
    if (selectedPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih printer terlebih dahulu")),
      );
      return;
    }

    try {
      await WindowsPrinterService.printThermal(
        printerName: selectedPrinter!,
        headerText: "THERMAL TEST",
        bodyText:
            "Test print berhasil.\nJika ini keluar berarti printer sudah benar.",
        qrData: "https://test.com",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Test print berhasil dikirim"),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal print: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Printer Settings"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
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
                                color: printer.status == "Online"
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
                      labelText: "Pilih Printer Thermal",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _savePrinter,
                      child: const Text("Simpan Printer"),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _testPrint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text("Test Print"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
