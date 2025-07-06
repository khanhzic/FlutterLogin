import 'package:flutter/material.dart';
import '../models/app_icons.dart';
import '../models/master_data.dart';
import '../services/master_data_service.dart';
import 'process_detail_page.dart';

class ProcessProductPage extends StatefulWidget {
  final String screenAction;
  final Product product;
  
  const ProcessProductPage({super.key, required this.screenAction, required this.product});

  @override
  State<ProcessProductPage> createState() => _ProcessProductPageState();
}

class _ProcessProductPageState extends State<ProcessProductPage> {
  List<Process> processes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProcesses();
  }

  Future<void> _loadProcesses() async {
    setState(() {
      _loading = true;
    });

    try {
      final masterData = await MasterDataService.getMasterData();
      if (masterData != null) {
        final productProcesses = masterData.getProcessesByProductId(widget.product.id);
        setState(() {
          processes = productProcesses;
        });
      }
    } catch (e) {
      print('Error loading processes: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  IconData _getProcessIcon(String processName) {
    // Map process names to icons
    switch (processName.toLowerCase()) {
      case 'đốt dây':
        return AppIcons.burnWire;
      case 'ráp':
        return AppIcons.wrench;
      case 'cắt nhôm':
        return Icons.content_cut;
      case 'cắt vải':
        return Icons.content_cut;
      case 'ghim':
        return Icons.push_pin;
      case 'lồng':
        return Icons.fit_screen;
      case 'đóng gói':
        return Icons.inventory;
      case 'vận chuyển':
        return Icons.local_shipping;
      default:
        return Icons.build; // Default icon
    }
  }

  Color _getProcessColor(String processName) {
    // Map process names to colors
    switch (processName.toLowerCase()) {
      case 'đốt dây':
        return Colors.red;
      case 'ráp':
        return Colors.grey[800]!;
      case 'cắt nhôm':
        return Colors.blue;
      case 'cắt vải':
        return Colors.purple;
      case 'ghim':
        return Colors.orange;
      case 'lồng':
        return Colors.teal;
      case 'đóng gói':
        return Colors.green;
      case 'vận chuyển':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.product.name} - Các công đoạn'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo_winsun.png',
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Hãy chọn công đoạn cần làm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.blue),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: processes.isNotEmpty
                        ? GridView.count(
                            crossAxisCount: 3,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.85,
                            children: processes.map((process) {
                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                color: Colors.white,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProcessDetailPage(
                                          processName: process.name,
                                          processId: process.id,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _getProcessIcon(process.name), 
                                          size: 48, 
                                          color: _getProcessColor(process.name),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          process.name,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          )
                        : const Center(
                            child: Text(
                              'Không có công đoạn nào cho sản phẩm này',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
} 