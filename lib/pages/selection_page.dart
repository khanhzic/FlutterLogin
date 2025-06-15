import 'package:flutter/material.dart';
import 'process_detail_page.dart'; // Import the new ProcessDetailPage

class SelectionPage extends StatelessWidget {
  const SelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn Công Đoạn Thực Hiện'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSelectionButton(context, 'CẦU VỒNG', Icons.palette),
            const SizedBox(height: 40),
            _buildSelectionButton(context, 'CUỐN', Icons.receipt),
            const SizedBox(height: 40),
            _buildSelectionButton(context, 'TỔ ONG + CỬA LƯỚI', Icons.grid_on),
            const SizedBox(height: 40),
            _buildSelectionButton(context, 'BẠT', Icons.texture),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionButton(BuildContext context, String text, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProcessDetailPage(processName: text),
          ),
        );
      },
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(300, 80),
        textStyle: const TextStyle(fontSize: 26),
      ),
    );
  }
} 