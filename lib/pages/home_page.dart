import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../models/user.dart';
import '../main.dart';
import 'selection_page.dart';

class HomePage extends StatelessWidget {
  final User user;

  HomePage({super.key, required this.user});

  void _handleLogout(BuildContext context) {
    context.read<AuthBloc>().add(LogoutButtonPressed());
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Home'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Open menu',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SelectionPage()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              _handleLogout(context);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                _handleLogout(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scan QR Code'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SelectionPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tài khoản: ' + user.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            const Text(
              'Thống kê tháng 06/2025',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildStatCard(
              color: Colors.green,
              icon: Icons.check,
              title: 'Đơn hàng hoàn thành',
              count: 0,
              staff: 0,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              color: Colors.yellow[700]!,
              icon: Icons.access_time,
              title: 'Đơn hàng đang làm',
              count: 0,
              staff: 0,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              color: Colors.red,
              icon: Icons.error,
              title: 'Đơn hàng bị lỗi',
              count: 0,
              staff: 0,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              color: Colors.cyan,
              icon: Icons.local_shipping,
              title: 'Đơn hàng đã vận chuyển',
              count: 0,
              staff: 0,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              color: Colors.grey,
              icon: Icons.refresh,
              title: 'Đơn hàng cần vận chuyển lại',
              count: 0,
              staff: 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required Color color,
    required IconData icon,
    required String title,
    required int count,
    required int staff,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              width: 48,
              height: 48,
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('$count', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Từ $staff nhân viên', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 