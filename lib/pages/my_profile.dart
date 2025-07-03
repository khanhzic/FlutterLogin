import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../models/user.dart';
import '../main.dart';
import 'home_page.dart';
import 'change_password_page.dart';


class MyProfilePage extends StatelessWidget {
  final User user;

  const MyProfilePage({super.key, required this.user});

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
        title: const Text('Tài khoản của tôi'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Open menu',
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.person),
        //     tooltip: 'User menu',
        //     onPressed: () {
        //       _scaffoldKey.currentState?.openEndDrawer();
        //     },
        //   ),
        // ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(user?.name ?? ''),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: const CircleAvatar(child: Icon(Icons.person)),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Tài khoản'),
              onTap: () {
                Navigator.pop(context);
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyProfilePage(user: user!)),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Công việc'),
              onTap: () {
                Navigator.pop(context);
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Đổi mật khẩu'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Đăng xuất'),
              onTap: () {
                Navigator.pop(context);
                _handleLogout(context);
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
              color: Colors.yellow,
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
                  Text('count', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Từ staff nhân viên', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 