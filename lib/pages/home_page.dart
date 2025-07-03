import 'package:flutter/material.dart';
import 'process_detail_page.dart'; // Import the new ProcessDetailPage
import '../models/app_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import 'change_password_page.dart'; // Import the new ChangePasswordPage
import 'process_product_page.dart'; // Import the new ProcessProductPage
import 'my_profile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  User? user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      final userJson = jsonDecode(userString);
      setState(() {
        user = User.fromJson(userJson);
      });
    }
  }

  void _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user');
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Công việc hôm nay'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Open menu',
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
                  _buildGridCard(context, 'Đốt dây', AppIcons.burnWire, Colors.red),
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
                  _buildGridCard(context, 'Cầu vồng', AppIcons.rainbow, Colors.red, isProduct: true),
                  _buildGridCard(context, 'Cuốn', AppIcons.scroll, Colors.green, isProduct: true),
                  _buildGridCard(context, 'Tổ ong + Cửa lưới', AppIcons.honeycomb, Colors.amber, isProduct: true),
                  _buildGridCard(context, 'Bạt', AppIcons.net, Colors.blue, isProduct: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, String text, IconData icon, Color iconColor, {bool isProduct = false}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (isProduct) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProcessProductPage(screenAction: text),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProcessDetailPage(processName: text),
              ),
            );
          }
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