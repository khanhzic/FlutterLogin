import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_common.dart';

class CompleteDeliveryPage extends StatefulWidget {
  const CompleteDeliveryPage({super.key});

  @override
  State<CompleteDeliveryPage> createState() => _CompleteDeliveryPageState();
}

class _CompleteDeliveryPageState extends State<CompleteDeliveryPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isScanning = false;
  List<Map<String, dynamic>> deliveryItems = [];
  String? _qrErrorMessage;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCode;
  final TextEditingController _noteController = TextEditingController();
  XFile? _pickedImage;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchDeliveryItems();
  }

  Future<void> _fetchDeliveryItems() async {
    setState(() { _loading = true; });
    try {
      final items = await ApiCommon.getListDeliveryItems();
      setState(() {
        deliveryItems = items;
      });
    } catch (e) {
      // handle error, optionally show a message
    } finally {
      setState(() { _loading = false; });
    }
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_searchText.isEmpty) {
      final sorted = List<Map<String, dynamic>>.from(deliveryItems);
      sorted.sort((a, b) => (a['code'] as String).compareTo(b['code'] as String));
      return sorted;
    }
    final filtered = deliveryItems.where((item) => (item['code'] as String).toLowerCase().contains(_searchText.toLowerCase())).toList();
    filtered.sort((a, b) => (a['code'] as String).compareTo(b['code'] as String));
    return filtered;
  }

  @override
  void dispose() {
    controller?.dispose();
    _searchController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchText = _searchController.text.trim();
    });
  }

  Future<bool> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) {
      return true;
    }
    status = await Permission.camera.request();
    return status.isGranted;
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null) {
        final qrData = scanData.code!;
        final exists = _filteredItems.any((item) => '${item['code']}_${item['total_quantity']}' == qrData);
        if (exists) {
          setState(() {
            _selectedCode = qrData;
            _qrErrorMessage = null;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showFinishTransportDialog(qrData);
          });
        } else {
          setState(() {
            _selectedCode = null;
            _qrErrorMessage = 'Mã sản phẩm không tồn tại';
          });
        }
        controller.pauseCamera();
        Navigator.pop(context);
      }
    });
  }

  void _showFinishTransportDialog(String code) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Hoàn thành cho mã: $code', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Chú thích',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Chụp ảnh'),
                      onPressed: () async {
                        await _captureImage();
                        setState(() {});
                      },
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('Tải ảnh lên'),
                      onPressed: () async {
                        await _pickImage();
                        setState(() {});
                      },
                    ),
                  ],
                ),
                if (_pickedImage != null) ...[
                  const SizedBox(height: 12),
                  Image.file(
                    File(_pickedImage!.path),
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                // Handle submit here
                Navigator.of(context).pop();
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  void _scanQRCode() async {
    bool hasPermission = await _requestCameraPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cần quyền truy cập camera để quét mã QR'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _isScanning = true;
    });
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Quét mã QR'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _isScanning = false;
                });
                Navigator.pop(context);
              },
            ),
          ),
          body: QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.green,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: MediaQuery.of(context).size.width * 0.8,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _pickedImage = image;
    });
  }

  Future<void> _captureImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    setState(() {
      _pickedImage = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoàn thành vận chuyển'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Quét mã', style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _scanQRCode,
                        ),
                      ),
                    ],
                  ),
                  if (_qrErrorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _qrErrorMessage!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Tìm kiếm mã sản phẩm',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      setState(() {
                        _searchText = _searchController.text.trim();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Danh sách mã đang có:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _filteredItems.isEmpty
                        ? const Center(child: Text('Chưa có mã nào đang vận chuyển.'))
                        : Scrollbar(
                            child: ListView.separated(
                              itemCount: _filteredItems.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final item = _filteredItems[index];
                                final label = '${item['code']}_${item['total_quantity']}';
                                return ListTile(
                                  leading: const Icon(Icons.qr_code),
                                  title: Text(
                                    label,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  onTap: () {
                                    _showFinishTransportDialog(label);
                                  },
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
} 