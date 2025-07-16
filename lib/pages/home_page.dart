import 'package:flutter/material.dart';
import 'process_detail_page.dart'; // Import the new ProcessDetailPage
import '../models/app_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../models/working_process.dart';
import '../models/master_data.dart';
import 'change_password_page.dart'; // Import the new ChangePasswordPage
import 'process_product_page.dart'; // Import the new ProcessProductPage
import 'my_profile.dart';
import '../services/api_common.dart';
import '../services/master_data_service.dart';
import '../config/app_config.dart';
import '../widgets/profile_image_widget.dart';
import 'about_page.dart'; // Import the new AboutPage
import '../main.dart'; // Để dùng routeObserver
import 'package:intl/intl.dart'; // Thêm dòng này để dùng DateFormat
import 'handle_detail_page.dart'; // Import the new HandleDetailPage
import '../services/api_common.dart' show TokenExpiredException;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  User? user;
  List<WorkingProcess> workingProcesses = [];
  MasterData? masterData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ApiCommon.checkAndHandleTokenExpired();
      } on TokenExpiredException {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
        return;
      }
      _loadUserData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when coming back to this page
    _loadUserData(); // Gọi lại API
  }

  Future<void> _loadUserData() async {
    setState(() {
      _loading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      final token = prefs.getString('access_token');

      if (userString != null) {
        final userJson = jsonDecode(userString);
        setState(() {
          user = User.fromJson(userJson);
        });
      }

      // Load master data
      if (token != null) {
        // First try to get cached data
        var masterDataResult = await MasterDataService.getMasterData(context);
        
        // If master data is null, force refresh from API
        if (masterDataResult == null) {
          masterDataResult = await MasterDataService.getMasterData(context, forceRefresh: true);
        }
        
        if (masterDataResult != null) {
          setState(() {
            masterData = masterDataResult;
          });
        }
      }

      // Call API to get user data with working processes
      if (token != null) {
        final userData = await ApiCommon.getUserData(context);
        if (userData != null && userData['working_processes'] != null) {
          final processesList = userData['working_processes'] as List;
          List<WorkingProcess> sortedProcesses = processesList
              .map((process) => WorkingProcess.fromJson(process))
              .toList();
          // Sắp xếp theo startTime tăng dần
          sortedProcesses.sort((a, b) {
            DateTime? aTime = DateTime.tryParse(a.startTime);
            DateTime? bTime = DateTime.tryParse(b.startTime);
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return aTime.compareTo(bTime);
          });
          setState(() {
            workingProcesses = sortedProcesses;
          });
        }
      }
    } catch (e) {
      // Handle error silently or show a snackbar
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    if (token != null) {
      // Force refresh master data
      final masterDataResult = await MasterDataService.getMasterData(context, forceRefresh: true);
      if (masterDataResult != null) {
        setState(() {
          masterData = masterDataResult;
        });
      }
      
      // Refresh user data with working processes
      final userData = await ApiCommon.getUserData(context);
      if (userData != null && userData['working_processes'] != null) {
        final processesList = userData['working_processes'] as List;
        List<WorkingProcess> sortedProcesses = processesList
            .map((process) => WorkingProcess.fromJson(process))
            .toList();
        // Sắp xếp theo startTime tăng dần
        sortedProcesses.sort((a, b) {
          DateTime? aTime = DateTime.tryParse(a.startTime);
          DateTime? bTime = DateTime.tryParse(b.startTime);
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return aTime.compareTo(bTime);
        });
        setState(() {
          workingProcesses = sortedProcesses;
        });
      }
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

  Widget _buildInProgressIndicator() {
    if (workingProcesses.isEmpty) {
      return const SizedBox.shrink(); // Return empty space if no working processes
    }

    // Tính toán width cho vừa 2 card trên màn hình
    final double cardWidth = MediaQuery.of(context).size.width / 2.2;
    return SizedBox(
      height: 170, // Chiều cao card, chỉnh cho phù hợp
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: workingProcesses.length,
        itemBuilder: (context, index) {
          final wp = workingProcesses[index];
          final process = masterData?.processes.firstWhere(
            (p) => p.id == wp.processId,
            orElse: () => Process(id: 0, name: 'Unknown', code: ''),
          );
          return Container(
            width: cardWidth,
            margin: EdgeInsets.only(
              left: index == 0 ? 16 : 8,
              right: index == workingProcesses.length - 1 ? 16 : 8,
            ),
            child: Card(
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
                      builder: (context) => HandleDetailPage(
                        code: wp.order.code,
                        processId: wp.processId,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(_getProcessIcon(process?.name ?? ''), size: 44, color: _getProcessColor(process?.name ?? '')),
                      Text(
                        process?.name ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                      if (wp.startTime.isNotEmpty) ...[
                        Text(
                          _formatStartTime(wp.startTime),
                          style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatStartTime(String startTime) {
    try {
      final dt = DateFormat('yyyy-MM-dd HH:mm:ss').parse(startTime);
      return 'Bắt đầu lúc: ${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour}h:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Bắt đầu lúc: $startTime';
    }
  }

  // Card cho sản phẩm (code cũ, không có thời gian, style cũ)
  Widget _buildProductCard(BuildContext context, String text, IconData icon, Color iconColor, {Product? product, Process? process}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (product != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProcessProductPage(screenAction: text, product: product),
              ),
            );
          } else if (process != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProcessDetailPage(
                  processName: text,
                  processId: process.id,
                ),
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
              currentAccountPicture: ProfileImageWidget(
                profilePhotoPath: user?.profilePhotoPath,
                radius: 40.0,
              ),
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
      backgroundColor: const Color(0xFFF7F8FA),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
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
                      
                      if (workingProcesses.isNotEmpty) ...[
                        const Text(
                          'Các việc đang làm',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
                        ),
                        const SizedBox(height: 10),
                        _buildInProgressIndicator(),
                        const SizedBox(height: 10),
                        if (masterData != null)
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 1.2,
                            children: masterData!.processes
                                .where((process) => process.parentId == null) // Only show top-level processes
                                .take(2) // Limit to 2 items
                                .map((process) {
                              return _buildGridCard(
                                context,
                                process.name,
                                _getProcessIcon(process.name),
                                _getProcessColor(process.name),
                                product: null,
                                process: process,
                              );
                            }).toList(),
                          )
                        else
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 1.2,
                            children: [
                              _buildGridCard(context, 'Đốt dây', AppIcons.burnWire, Colors.red, product: null, process: null),
                            ],
                          ),
                        const SizedBox(height: 30),
                      ],
                      const Text(
                        'Các sản phẩm',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      if (masterData != null && masterData!.products.isNotEmpty)
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1.2,
                          children: masterData!.products.map((product) {
                            return _buildProductCard(
                              context, 
                              product.name, 
                              _getProductIcon(product.name), 
                              _getProductColor(product.name), 
                              product: product,
                              process: null,
                            );
                          }).toList(),
                        )
                      else
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              'Không có sản phẩm nào',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildGridCard(BuildContext context, String text, IconData icon, Color iconColor, {bool isProduct = false, Product? product, Process? process, String? startTime}) {
    String? formattedStartTime;
    if (startTime != null && startTime.isNotEmpty) {
      try {
        final dt = DateFormat('yyyy-MM-dd HH:mm:ss').parse(startTime);
        formattedStartTime = 'Bắt đầu lúc: ${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour}h:${dt.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        formattedStartTime = 'Bắt đầu lúc: $startTime';
      }
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (isProduct && product != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProcessProductPage(screenAction: text, product: product),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProcessDetailPage(
                  processName: text,
                  processId: process?.id,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8), // giảm padding dọc
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Đẩy thời gian xuống dưới cùng
            children: [
              Icon(icon, size: 44, color: iconColor), // giảm icon size
              Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              if (formattedStartTime != null) ...[
                Text(
                  formattedStartTime,
                  style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getProductIcon(String productName) {
    // Map product names to icons
    switch (productName.toLowerCase()) {
      case 'cầu vồng':
        return AppIcons.rainbow;
      case 'cuốn':
        return AppIcons.scroll;
      case 'tổ ong và cửa lưới':
      case 'tổ ong và cửa lưới':
        return AppIcons.honeycomb;
      case 'bạt':
        return AppIcons.net;
      default:
        return Icons.inventory; // Default icon
    }
  }

  Color _getProductColor(String productName) {
    // Map product names to colors
    switch (productName.toLowerCase()) {
      case 'cầu vồng':
        return Colors.red;
      case 'cuốn':
        return Colors.green;
      case 'tổ ong và cửa lưới':
      case 'tổ ong và cửa lưới':
        return Colors.amber;
      case 'bạt':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getProcessIcon(String processName) {
    // Map process names to icons
    switch (processName.toLowerCase()) {
      case 'đốt dây':
        return AppIcons.burnWire;
      case 'ráp':
        return AppIcons.wrench;
      case 'cắt nhôm':
        return Icons.content_cut;
      case 'cắt vải':
        return Icons.content_cut;
      case 'ghim':
        return Icons.push_pin;
      case 'lồng':
        return Icons.fit_screen;
      default:
        return Icons.build; // Default icon
    }
  }

  Color _getProcessColor(String processName) {
    // Map process names to colors
    switch (processName.toLowerCase()) {
      case 'đốt dây':
        return Colors.red;
      case 'ráp':
        return Colors.grey[800]!;
      case 'cắt nhôm':
        return Colors.blue;
      case 'cắt vải':
        return Colors.purple;
      case 'ghim':
        return Colors.orange;
      case 'lồng':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
} 