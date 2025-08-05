import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_common.dart';
import '../services/products_service.dart';
import '../config/app_config.dart';

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
  void initState() {
    super.initState();
    print('🔍 DEBUG: TransporterPage initState called');
    print('🔍 DEBUG: Initial scannedCodes length: ${scannedCodes.length}');
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
    print('🔍 DEBUG: _onQRViewCreated called');
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      print('🔍 DEBUG: QR stream received: ${scanData.code}');
      if (scanData.code != null) {
        final qrData = scanData.code!;
        print('🔍 DEBUG: QR Code scanned: $qrData');
        if (ProductsService.isValidQRCode(qrData)) {
          print('🔍 DEBUG: QR code is valid, adding to list');
          setState(() async {
            // if (!scannedCodes.contains(qrData)) {
            //   scannedCodes.add(qrData);
            //   print('🔍 DEBUG: Added QR code to list. Total codes: ${scannedCodes.length}');
            //   print('🔍 DEBUG: scannedCodes content: $scannedCodes');
            // } else {
            //   print('🔍 DEBUG: QR code already exists in list');
            // }
            final parseData = ProductsService.parseQRCode(qrData);
            if (await ApiCommon.existedItemOnDeliveryList(parseData.orderCode)) {
              scannedCodes.add(parseData.orderCode);
              _isScanning = false;
              _qrErrorMessage = null;
            } else {
              _isScanning = false;
              _qrErrorMessage = "Sản phẩm không tồn tại trong danh sách vận chuyển";
            }
          });
          print('🔍 DEBUG: setState completed');
        } else {
          print('🔍 DEBUG: Invalid QR code: $qrData');
          setState(() {
            _qrErrorMessage = MESSAGE_ERROR_QR_CODE;
          });
        }
        controller.pauseCamera();
        Navigator.pop(context);
      }
    });
  }

  // bool _isValidQRCode(String qrData) {
  //   final parts = qrData.split('_');
  //   if (parts.length != 2) return false;
  //   final orderCode = parts[0];
  //   final quantityStr = parts[1];
  //   if (orderCode.isEmpty) return false;
  //   try {
  //     final quantity = int.parse(quantityStr);
  //     return quantity > 0;
  //   } catch (e) {
  //     return false;
  //   }
  // }

  void _scanQRCode() async {
    print('🔍 DEBUG: _scanQRCode called');
    bool hasPermission = await _requestCameraPermission();
    print('🔍 DEBUG: Camera permission: $hasPermission');
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
    });
    print('🔍 DEBUG: Opening QR scanner dialog');
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Quét mã QR'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                print('🔍 DEBUG: Back button pressed, closing scanner');
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
    print('🔍 DEBUG: QR scanner dialog closed');
  }

  void _onSearchChanged() {
    print('🔍 DEBUG: _onSearchChanged called with text: "${_searchController.text}"');
    setState(() {
      _searchText = _searchController.text.trim();
    });
    print('🔍 DEBUG: _searchText updated to: "$_searchText"');
  }

  List<String> get _filteredCodes {
    print('🔍 DEBUG: _filteredCodes getter called');
    if (_searchText.isEmpty) {
      final sorted = List<String>.from(scannedCodes);
      sorted.sort();
      print('🔍 DEBUG: No search text, returning ${sorted.length} sorted codes');
      return sorted;
    }
    final filtered = scannedCodes.where((code) => code.toLowerCase().contains(_searchText.toLowerCase())).toList();
    filtered.sort();
    print('🔍 DEBUG: With search text "$_searchText", returning ${filtered.length} filtered codes');
    return filtered;
  }

  Future<void> _startTransport() async {
    print('🔍 DEBUG: _startTransport called with ${scannedCodes.length} codes');
    print('🔍 DEBUG: Codes to send: $scannedCodes');
    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });
    try {
      final result = await ApiCommon.startTransport(context, scannedCodes, await ApiCommon.getDeliveryListFromCache());
      print('🔍 DEBUG: API result: $result');
      if (result['status'] == 'success') {
        setState(() {
          _resultMessage = 'Gửi vận chuyển thành công!';
          print('🔍 DEBUG: Clearing scannedCodes after success');
          scannedCodes.clear();
          _searchController.clear();
        });
        print('🔍 DEBUG: scannedCodes cleared, new length: ${scannedCodes.length}');
      } else {
        setState(() {
          _resultMessage = result['message'] ?? 'Có lỗi xảy ra khi gửi vận chuyển.';
        });
      }
    } catch (e) {
      print('🔍 DEBUG: Error in _startTransport: $e');
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
    print('🔍 DEBUG: Building transporter page. scannedCodes length: ${scannedCodes.length}, _filteredCodes length: ${_filteredCodes.length}');
    print('🔍 DEBUG: scannedCodes content: $scannedCodes');
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
            // Debug info hiển thị trực tiếp trên UI
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.yellow.shade100,
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'DEBUG: scannedCodes.length = ${scannedCodes.length}, content = $scannedCodes',
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
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
