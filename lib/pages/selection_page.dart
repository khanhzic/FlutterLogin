import 'package:flutter/material.dart';
import 'process_detail_page.dart'; // Import the new ProcessDetailPage
import '../models/app_icons.dart';

class SelectionPage extends StatelessWidget {
  const SelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/logo_winsun.png',
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Các việc đang làm',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.2,
                children: [
                  _buildGridCard(context, 'Đốt dây', AppIcons.burnWire, Colors.grey[800]!),
                  _buildGridCard(context, 'Ráp', AppIcons.wrench, Colors.grey[800]!),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Các sản phẩm',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.2,
                children: [
                  _buildGridCard(context, 'Cầu vồng', AppIcons.rainbow, Colors.grey[800]!),
                  _buildGridCard(context, 'Cửa lưới', AppIcons.net, Colors.grey[800]!),
                  _buildGridCard(context, 'Tổ ong', AppIcons.honeycomb, Colors.grey[800]!),
                  _buildGridCard(context, 'Bạt', AppIcons.tarp, Colors.grey[800]!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, String text, IconData icon, Color iconColor) {
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
              builder: (context) => ProcessDetailPage(processName: text),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 56, color: iconColor),
              const SizedBox(height: 12),
              Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 