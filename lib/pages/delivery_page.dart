import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_common.dart';

class DeliveryPage extends StatefulWidget {
  const DeliveryPage({super.key});

  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isScanning = false;
  List<String> scannedCodes = [];
  String? _qrErrorMessage;
  String _searchText = '';
  bool _isLoading = false;
  String? _resultMessage;
  final TextEditingController _searchController = TextEditingController();

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
        final qrData = scanData.code!;
        if (_isValidQRCode(qrData)) {
          setState(() {
            if (!scannedCodes.contains(qrData)) {
              scannedCodes.add(qrData);
            }
            _isScanning = false;
            _qrErrorMessage = null;
          });
        } else {
          setState(() {
            _qrErrorMessage = 'Mã sản phẩm không hợp lệ, hãy quét lại đúng mã!';
          });
        }
        controller.pauseCamera();
        Navigator.pop(context);
      }
    });
  }

  bool _isValidQRCode(String qrData) {
    final parts = qrData.split('_');
    if (parts.length != 2) return false;
    final orderCode = parts[0];
    final quantityStr = parts[1];
    if (orderCode.isEmpty) return false;
    try {
      final quantity = int.parse(quantityStr);
      return quantity > 0;
    } catch (e) {
      return false;
    }
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

  void _onSearchChanged() {
    setState(() {
      _searchText = _searchController.text.trim();
    });
  }

  List<String> get _filteredCodes {
    if (_searchText.isEmpty) {
      final sorted = List<String>.from(scannedCodes);
      sorted.sort();
      return sorted;
    }
    final filtered = scannedCodes.where((code) => code.toLowerCase().contains(_searchText.toLowerCase())).toList();
    filtered.sort();
    return filtered;
  }

  Future<void> _startTransport() async {
    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });
    try {
      final result = await ApiCommon.startTransport(scannedCodes);
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
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Bắt đầu', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: scannedCodes.isNotEmpty && !_isLoading ? _startTransport : null,
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
            const Text('Danh sách mã đã quét:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredCodes.isEmpty
                  ? const Center(child: Text('Chưa có mã nào được quét.'))
                  : Scrollbar(
                      child: ListView.separated(
                        itemCount: _filteredCodes.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.qr_code),
                            title: Text(
                              _filteredCodes[index],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
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