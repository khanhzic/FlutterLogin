import 'package:flutter/material.dart';
import '../services/api_common.dart';
import '../widgets/loading_overlay.dart';

class DemoLoadingPage extends StatefulWidget {
  const DemoLoadingPage({super.key});

  @override
  State<DemoLoadingPage> createState() => _DemoLoadingPageState();
}

class _DemoLoadingPageState extends State<DemoLoadingPage> {
  final LoadingManager _loadingManager = LoadingManager();
  String _result = '';

  @override
  void initState() {
    super.initState();
    // Khởi tạo LoadingManager cho ApiCommon
    ApiCommon.setLoadingManager(_loadingManager);
  }

  Future<void> _testApiCall() async {
    try {
      final result = await ApiCommon.getUserReport();
      setState(() {
        _result = 'API call completed: ${result != null ? 'Success' : 'Failed'}';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _loadingManager,
      builder: (context, child) {
        return LoadingOverlay(
          isLoading: _loadingManager.isLoading,
          loadingText: _loadingManager.loadingText,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Loading Overlay Demo'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _testApiCall,
                    child: const Text('Test API Call'),
                  ),
                  const SizedBox(height: 20),
                  Text(_result),
                  const SizedBox(height: 20),
                  const Text(
                    'Khi nhấn nút "Test API Call", bạn sẽ thấy loading overlay xuất hiện tự động trong khi API đang được gọi.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 