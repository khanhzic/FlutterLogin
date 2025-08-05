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
import '../widgets/profile_image_widget.dart';
import '../pages/about_page.dart';


class MyProfilePage extends StatefulWidget {
  final User user;

  const MyProfilePage({super.key, required this.user});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Current month
  int completed = 0;
  int pending = 0;
  int error = 0;
  int transported = 0;
  int retransport = 0;
  // Last month
  int lastCompleted = 0;
  int lastPending = 0;
  int lastError = 0;
  int lastTransported = 0;
  int lastRetransport = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    setState(() { _loading = true; });
    try {
      final report = await ApiCommon.getUserReport(context);
      final data = (report != null && report['data'] != null && report['data'] is Map)
          ? report['data'] as Map
          : <String, dynamic>{};
      final statistics = (data.isNotEmpty && data['statistics'] != null && data['statistics'] is Map)
          ? data['statistics'] as Map
          : <String, dynamic>{};
      final current = statistics['current_month'] as Map? ?? {};
      final last = statistics['last_month'] as Map? ?? {};
      setState(() {
        completed = current['completed'] ?? 0;
        pending = current['pending'] ?? 0;
        error = current['error'] ?? 0;
        transported = current['transported'] ?? 0;
        retransport = current['retransport'] ?? 0;
        lastCompleted = last['completed'] ?? 0;
        lastPending = last['pending'] ?? 0;
        lastError = last['error'] ?? 0;
        lastTransported = last['transported'] ?? 0;
        lastRetransport = last['retransport'] ?? 0;
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
                accountName: Text(widget.user.name ?? ''),
                accountEmail: Text(widget.user.email ?? ''),
                currentAccountPicture: ProfileImageWidget(
                  profilePhotoPath: widget.user.profilePhotoPath,
                  radius: 40.0,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: const Text('Tài khoản'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyProfilePage(user: widget.user)),
                  );
                                },
              ),
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: const Text('Công việc'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Giới thiệu'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutPage()),
                  );
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
                  'Tài khoản: ${widget.user.name}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Text(
                  'Thống kê tháng hiện tại: $monthYear',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_loading)
                  const Center(child: CircularProgressIndicator()),
                if (!_loading) ...[
                  GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75, // taller boxes
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
                  const SizedBox(height: 24),
                  const Text(
                    'Thống kê tháng trước',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75, // taller boxes
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStatCard(color: Colors.green, icon: Icons.check, title: 'Hoàn thành', count: lastCompleted),
                      _buildStatCard(color: Colors.yellow, icon: Icons.access_time, title: 'Đang làm', count: lastPending),
                      _buildStatCard(color: Colors.red, icon: Icons.error, title: 'Lỗi', count: lastError),
                      _buildStatCard(color: Colors.cyan, icon: Icons.local_shipping, title: 'Đã vận chuyển', count: lastTransported),
                      _buildStatCard(color: Colors.grey, icon: Icons.refresh, title: 'Vận chuyển lại', count: lastRetransport),
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('$count', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
} 