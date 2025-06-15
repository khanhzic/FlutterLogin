import 'package:flutter/material.dart';

// Added a comment to force re-evaluation
class ProcessStatusPage extends StatelessWidget {
  final String processName;

  const ProcessStatusPage({super.key, required this.processName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(processName),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Quy trình "$processName" đang diễn ra',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildStatusButton(context, 'Hoàn thành', Colors.green, () {
              // TODO: Implement "Hoàn thành" logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nút "Hoàn thành" đã được nhấn!')),
              );
              Navigator.pop(context); // Quay lại màn hình trước
            }),
            const SizedBox(height: 20),
            _buildStatusButton(context, 'Tạm dừng', Colors.orange, () {
              // TODO: Implement "Tạm dừng" logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nút "Tạm dừng" đã được nhấn!')),
              );
            }),
            const SizedBox(height: 20),
            _buildStatusButton(context, 'Dừng lỗi', Colors.red, () {
              // TODO: Implement "Dừng lỗi" logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nút "Dừng lỗi" đã được nhấn!')),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(
      BuildContext context, String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 250, // Fixed width for buttons
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          textStyle: const TextStyle(fontSize: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(text),
      ),
    );
  }
} 