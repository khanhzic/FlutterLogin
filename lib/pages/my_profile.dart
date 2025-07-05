import 'package:flutter/material.dart';
import 'package:login_app/pages/change_password_page.dart';
import 'package:login_app/pages/home_page.dart';
import '../models/user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/api_common.dart';
import 'dart:core';
import '../main.dart';


class MyProfilePage extends StatefulWidget {
  final User user;

  const MyProfilePage({super.key, required this.user});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int completed = 0;
  int pending = 0;
  int error = 0;
  int transported = 0;
  int retransport = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    setState(() { _loading = true; });
    try {
      final report = await ApiCommon.getUserReport();
      final data = (report != null && report is Map && report['data'] != null && report['data'] is Map)
          ? report['data'] as Map
          : <String, dynamic>{};
      final stats = (data.isNotEmpty && data['statistics'] != null && data['statistics'] is Map)
          ? data['statistics'] as Map
          : <String, dynamic>{};
      setState(() {
        completed = stats['completed'] ?? 0;
        pending = stats['pending'] ?? 0;
        error = stats['error'] ?? 0;
        transported = stats['transported'] ?? 0;
        retransport = stats['retransport'] ?? 0;
      });
    } catch (e) {
      // handle error if needed
    } finally {
      setState(() { _loading = false; });
    }
  }

  void _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user');
    if (mounted) {
      context.read<AuthBloc>().add(LogoutButtonPressed());
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthYear = DateFormat('MM/yyyy').format(now);
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              UserAccountsDrawerHeader(
                accountName: Text(widget.user?.name ?? ''),
                accountEmail: Text(widget.user?.email ?? ''),
                currentAccountPicture: const CircleAvatar(child: Icon(Icons.person)),
              ),
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: const Text('Tài khoản'),
                onTap: () {
                  Navigator.pop(context);
                  if (widget.user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyProfilePage(user: widget.user!)),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: const Text('Công việc'),
                onTap: () {
                  Navigator.pop(context);
                  if (widget.user != null) {
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
        appBar: AppBar(
          title: const Text('Thông tin tài khoản'),
          leading: IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Open menu',
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tài khoản: ' + widget.user.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Text(
                  'Thống kê tháng $monthYear',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_loading)
                  const Center(child: CircularProgressIndicator()),
                if (!_loading) ...[
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1, // square
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStatCard(color: Colors.green, icon: Icons.check, title: 'Hoàn thành', count: completed),
                      _buildStatCard(color: Colors.yellow, icon: Icons.access_time, title: 'Đang làm', count: pending),
                      _buildStatCard(color: Colors.red, icon: Icons.error, title: 'Lỗi', count: error),
                      _buildStatCard(color: Colors.cyan, icon: Icons.local_shipping, title: 'Đã vận chuyển', count: transported),
                      _buildStatCard(color: Colors.grey, icon: Icons.refresh, title: 'Vận chuyển lại', count: retransport),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required Color color,
    required IconData icon,
    required String title,
    required int count,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                width: 36,
                height: 36,
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('$count', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
} 