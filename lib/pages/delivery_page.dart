import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_common.dart';
import '../services/products_service.dart';
import '../config/app_config.dart';
import '../models/order_code.dart';

class DeliveryPage extends StatefulWidget {
  const DeliveryPage({super.key});

  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isScanning = false;
  List<OrderCode> scannedCodes = [];
  String? _qrErrorMessage;
  String _searchText = '';
  bool _isLoading = false;
  String? _resultMessage;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();
    _searchController.dispose();
    super.dispose();
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
        try {
          final qrData = scanData.code!;
          final parseData = ProductsService.parseQRCode(qrData);
          
          // Kiểm tra xem mã đã tồn tại trong list chưa
          if (_isCodeDuplicate(parseData.orderCode)) {
            // Mã đã tồn tại - đóng camera và hiển thị thông báo lỗi
            controller.pauseCamera();
            Navigator.pop(context);
            
            // Hiển thị thông báo lỗi sau khi trở về màn hình chính
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _qrErrorMessage = 'Mã ${parseData.orderCode} đã tồn tại trong danh sách!';
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Mã ${parseData.orderCode} đã tồn tại! Vui lòng scan mã khác.'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'Đóng',
                    textColor: Colors.white,
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  ),
                ),
              );
            });
          } else {
            // Mã mới - thêm vào danh sách và hiển thị thông báo thành công
            controller.pauseCamera();
            Navigator.pop(context);
            
            // Thêm vào danh sách sau khi trở về màn hình chính
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                scannedCodes.add(parseData);
                _qrErrorMessage = null;
              });
              
              // Lưu vào delivery list
              ApiCommon.addItemToDeliveryList(parseData);
              
              // Hiển thị thông báo thành công
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã thêm mã ${parseData.orderCode} vào danh sách!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            });
          }
        } catch (e) {
          // Lỗi parse QR code
          controller.pauseCamera();
          Navigator.pop(context);
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _qrErrorMessage = MESSAGE_ERROR_QR_CODE;
            });
          });
        }
      }
    });
  }

  void _scanQRCode() async {
    bool hasPermission = await _requestCameraPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(MESSAGE_ERROR_CAMERA_PERMISSION),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _isScanning = true;
      _qrErrorMessage = null; // Xóa thông báo lỗi cũ khi bắt đầu quét mới

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

  void _onSearchChanged() {
    setState(() {
      _searchText = _searchController.text.trim();
    });
  }

  // Kiểm tra xem mã có tồn tại trong list chưa
  bool _isCodeDuplicate(String orderCode) {
    return scannedCodes.any((item) => item.orderCode == orderCode);
  }



  List<OrderCode> get _filteredCodes {
    if (_searchText.isEmpty) {
      final sorted = List<OrderCode>.from(scannedCodes);
      sorted.sort((a, b) => a.orderCode.compareTo(b.orderCode));
      return sorted;
    }
    final filtered = scannedCodes.where((code) => code.orderCode.toLowerCase().contains(_searchText.toLowerCase())).toList();
    filtered.sort((a, b) => a.orderCode.compareTo(b.orderCode));
    return filtered;
  }

  Future<void> _startTransport() async {
    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });
    try {
      final result = await ApiCommon.startTransport(context, scannedCodes.map((item) => item.orderCode).toList(), await ApiCommon.getDeliveryListFromCache());
      if (result['status'] == 'success') {
        setState(() {
          _resultMessage = 'Gửi vận chuyển thành công!';
          scannedCodes.clear();
          _searchController.clear();
        });
      } else {
        setState(() {
          _resultMessage = result['message'] ?? 'Có lỗi xảy ra khi gửi vận chuyển.';
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = 'Có lỗi xảy ra khi gửi vận chuyển.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vận chuyển'),
        centerTitle: true,
      ),
      body: Padding(
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
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: scannedCodes.isNotEmpty && !_isLoading ? _startTransport : null,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Bắt đầu', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
            if (_qrErrorMessage != null) ...[
              const SizedBox(height: 10),
              Text(_qrErrorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Tìm kiếm mã sản phẩm',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _onSearchChanged(),
              // No autofocus, so the list keeps focus
            ),
            const SizedBox(height: 16),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                children: [
                  const TextSpan(
                    text: 'Danh sách mã đã quét: ',
                    style: TextStyle(color: Colors.black),
                  ),
                  TextSpan(
                    text: '${scannedCodes.length}',
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredCodes.isEmpty
                  ? const Center(child: Text('Chưa có mã nào được quét.'))
                  : Scrollbar(
                      child: ListView.separated(
                        itemCount: _filteredCodes.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = _filteredCodes[index];
                          return ListTile(
                            leading: const Icon(Icons.qr_code),
                            title: Text(
                              item.orderCode,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: item.qrData.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    item.qrData,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                )
                              : null,
                          );
                        },
                      ),
                    ),
            ),
            if (_resultMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _resultMessage!,
                style: TextStyle(
                  color: _resultMessage == 'Gửi vận chuyển thành công!' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
