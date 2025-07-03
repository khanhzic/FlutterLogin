import 'package:flutter/material.dart';
import '../models/app_icons.dart';
import 'process_detail_page.dart';

class ProcessProductPage extends StatelessWidget {
  final String screenAction;
  const ProcessProductPage({super.key, required this.screenAction});

  static const List<_ProcessItem> processItems = [
    _ProcessItem('Cắt nhôm', AppIcons.cutAluminum),
    _ProcessItem('Cắt vải', AppIcons.cutFabric),
    _ProcessItem('Đốt dây', AppIcons.burnWire),
    _ProcessItem('Ghim', AppIcons.pin),
    _ProcessItem('Lồng', AppIcons.puzzle),
    _ProcessItem('Ráp', AppIcons.wrench),
    _ProcessItem('Đóng gói', AppIcons.package),
    _ProcessItem('Vận chuyển', Icons.local_shipping),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Các công đoạn'),
        centerTitle: true,
      ),
      body: Padding(
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
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.95,
                children: processItems.map((item) {
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
                            builder: (context) => ProcessDetailPage(processName: item.label),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item.icon, size: 56, color: Colors.grey[800]),
                            const SizedBox(height: 12),
                            Text(
                              item.label,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessItem {
  final String label;
  final IconData icon;
  const _ProcessItem(this.label, this.icon);
} 