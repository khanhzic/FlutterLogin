import 'package:flutter/material.dart';
import 'process_detail_page.dart'; // Import the new ProcessDetailPage
import 'package:flutter_svg/flutter_svg.dart';

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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
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
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width / 2.2,
                  child: _buildGridCard(context, 'Đốt dây', 'assets/svg/dot_day.svg', Colors.grey[800]!),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 2.2,
                  child: _buildGridCard(context, 'Ráp', 'assets/svg/rap.svg', Colors.grey[800]!),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Các sản phẩm',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width / 2.2,
                  child: _buildGridCard(context, 'Cầu vồng', 'assets/svg/cau_vong.svg', null),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 2.2,
                  child: _buildGridCard(context, 'Cửa lưới', 'assets/svg/ghim.svg', Colors.grey[800]!),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 2.2,
                  child: _buildGridCard(context, 'Tổ ong', 'assets/svg/to_ong.svg', Colors.grey[800]!),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 2.2,
                  child: _buildGridCard(context, 'Bạt', 'assets/svg/bat.svg', Colors.grey[800]!),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, String text, String svgAsset, Color? iconColor) {
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
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconColor == null
                  ? SvgPicture.asset(svgAsset, width: 36, height: 36)
                  : SvgPicture.asset(svgAsset, width: 36, height: 36, color: iconColor),
              const SizedBox(height: 8),
              Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 