import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giới thiệu'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Winsun Việt Nam tự hào sở hữu hệ thống các nhãn hiệu đa dạng, đáp ứng mọi nhu cầu về rèm và giải pháp nội thất:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 16),
              Text(
                'Winsun: Chuyên cung cấp các sản phẩm rèm văn phòng, bạt che nắng mưa, rèm in tranh, tranh dán tường và rèm ngăn lạnh.',
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 8),
              Text(
                'Padora: Thương hiệu cao cấp cho dòng sản phẩm rèm cầu vồng, mang phong cách hiện đại và tinh tế.',
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 8),
              Text(
                'Winmax: Định vị trong lĩnh vực rèm tổ ong, cửa lưới chống muỗi, vách tổ ong, cửa nan nhôm, cửa nan nhựa và động cơ rèm tiên tiến.',
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 16),
              Text(
                'Với sự kết hợp giữa chất lượng vượt trội, thiết kế sáng tạo và dịch vụ chuyên nghiệp, Winsun Việt Nam cam kết mang đến giải pháp hoàn hảo cho không gian sống và làm việc của bạn.',
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 40),
              Center(
                child: Text(
                  'Phiên bản 1.0.1+4',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 