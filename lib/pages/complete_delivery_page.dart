import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'dart:typed_data';
import '../services/api_common.dart';
import '../services/api_common.dart' show TokenExpiredException;
import '../main.dart';

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
      final items = await ApiCommon.getListDeliveryItems(context);
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
      sorted.sort((a, b) => ((a['order']?['code'] ?? '') as String).compareTo((b['order']?['code'] ?? '') as String));
      return sorted;
    }
    final filtered = deliveryItems.where((item) => ((item['order']?['code'] ?? '') as String).toLowerCase().contains(_searchText.toLowerCase())).toList();
    filtered.sort((a, b) => ((a['order']?['code'] ?? '') as String).compareTo((b['order']?['code'] ?? '') as String));
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
        final exists = _filteredItems.any((item) => '${item['order']?['code'] ?? ''}_${item['order']?['total_quantity'] ?? ''}' == qrData);
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
    // Xóa ảnh cũ khi mở dialog mới
    setState(() {
      _pickedImage = null;
      _noteController.clear(); // Xóa cả note cũ
    });
    
    showDialog(
      context: context,
      barrierDismissible: false, // Không cho phép đóng bằng cách tap bên ngoài
      builder: (context) {
        return StatefulBuilder( // Sử dụng StatefulBuilder để có thể update UI trong dialog
          builder: (context, setDialogState) {
            return Dialog(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 600,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Hoàn thành cho mã: $code', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _noteController,
                              decoration: const InputDecoration(
                                labelText: 'Chú thích',
                                border: OutlineInputBorder(),
                                labelStyle: TextStyle(fontSize: 16),
                              ),
                              style: const TextStyle(fontSize: 16),
                              minLines: 3,
                              maxLines: 5,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.photo_camera, size: 24),
                                    label: const Text(
                                      'Chụp ảnh',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () async {
                                      final image = await _captureImageInDialog();
                                      if (image != null) {
                                        setDialogState(() {
                                          _pickedImage = image;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.image, size: 24),
                                    label: const Text(
                                      'Tải ảnh lên',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () async {
                                      final image = await _pickImageInDialog();
                                      if (image != null) {
                                        setDialogState(() {
                                          _pickedImage = image;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Khu vực hiển thị ảnh hoặc warning (khu vực đỏ)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _pickedImage == null ? Colors.red.shade50 : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _pickedImage == null ? Colors.red.shade200 : Colors.green.shade200,
                                  width: 2,
                                ),
                              ),
                              child: _pickedImage == null 
                                ? Row(
                                    children: [
                                      const Icon(Icons.warning, color: Colors.red, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '⚠️ Vui lòng chụp hoặc tải ảnh (bắt buộc)',
                                          style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                          const SizedBox(width: 8),
                                          const Text(
                                            '✅ Đã chụp ảnh thành công',
                                            style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: SizedBox(
                                          height: 120,
                                          width: double.infinity,
                                          child: Image.file(
                                            File(_pickedImage!.path),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                height: 120,
                                                color: Colors.grey.shade300,
                                                child: const Center(
                                                  child: Text('Lỗi tải ảnh', style: TextStyle(color: Colors.red)),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),

                                    ],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Hủy',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _pickedImage != null ? () {
                            Navigator.of(context).pop(); // Đóng dialog trước
                            _completeDelivery(code);
                          } : null, // Disable nếu chưa có ảnh
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pickedImage != null ? Colors.green : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Xác nhận',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<XFile?> _pickImageInDialog() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final compressedImage = await _compressImage(image);
      return compressedImage;
    }
    return null;
  }

  Future<XFile?> _captureImageInDialog() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final compressedImage = await _compressImage(image);
      return compressedImage;
    }
    return null;
  }

  Future<XFile?> _compressImage(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final compressedBytes = await FlutterImageCompress.compressWithList(
        Uint8List.fromList(bytes),
        minHeight: 1024,
        minWidth: 1024,
        quality: 85,
      );
      
      final compressedFile = File('${image.path}_compressed.jpg');
      await compressedFile.writeAsBytes(compressedBytes);
      
      final sizeInMB = compressedBytes.length / 1024 / 1024;
      final originalSizeInMB = bytes.length / 1024 / 1024;
      final compressionRatio = ((originalSizeInMB - sizeInMB) / originalSizeInMB * 100);
      
      print('🔍 DEBUG: Compressed image size: ${sizeInMB.toStringAsFixed(2)} MB');
      print('🔍 DEBUG: Compression ratio: ${compressionRatio.toStringAsFixed(1)}%');
      print('🔍 DEBUG: Ảnh đã chụp: ${compressedFile.path}');
      
      return XFile(compressedFile.path);
    } catch (e) {
      print('🔍 DEBUG: Error compressing image: $e');
      return image; // Return original if compression fails
    }
  }

  Future<int> _getImageSize() async {
    if (_pickedImage != null) {
      final file = File(_pickedImage!.path);
      return await file.length();
    }
    return 0;
  }

  void _completeDelivery(String code) async {
    // Kiểm tra bắt buộc chụp ảnh
    if (_pickedImage == null) {
      _showErrorAlert({'message': 'Vui lòng chụp hoặc tải ảnh trước khi hoàn thành.'});
      return;
    }
    
    setState(() { _loading = true; });
    try {
      // Tách code từ format "ORDER2001_102" thành "ORDER2001"
      final orderCode = code.split('_').first;
      
      final requestData = {
        'item_code': orderCode, // Chỉ gửi code, không có quantity
        'note': _noteController.text,
      };
      
      final respData = await ApiCommon.processAction(
        context: context,
        endpoint: 'delivery/complete',
        data: requestData,
        image: _pickedImage,
      );
      
      if (respData['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hoàn thành vận chuyển thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh danh sách từ server
          await _fetchDeliveryItems();
          
          // Nếu không còn mã nào, quay về màn hình trước đó
          if (deliveryItems.isEmpty) {
            Navigator.of(context).pop(); // Quay về màn hình vận chuyển
          }
          // Nếu còn mã thì ở lại màn hình hiện tại (Hoàn thành vận chuyển)
        }
      } else {
        _showErrorAlert(respData);
      }
    } on TokenExpiredException {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      _showErrorAlert({'message': 'Có lỗi không thể thực hiện. Hãy chụp màn hình và gửi cho admin'});
    } finally {
      if (mounted) {
        setState(() { _loading = false; });
      }
    }
  }

  void _showErrorAlert(Map<String, dynamic>? responseData) {
    String errorMessage = 'Có lỗi không thể thực hiện. Hãy chụp màn hình và gửi cho admin';
    if (responseData != null) {
      if (responseData['errors'] != null && responseData['errors'] is Map) {
        final errors = responseData['errors'] as Map<String, dynamic>;
        final errorMessages = <String>[];
        errors.forEach((field, messages) {
          if (messages is List) {
            for (final message in messages) {
              errorMessages.add('$field: $message');
            }
          } else if (messages is String) {
            errorMessages.add('$field: $messages');
          }
        });
        if (errorMessages.isNotEmpty) {
          errorMessage = errorMessages.join('\n');
        }
      } else if (responseData['message'] != null) {
        errorMessage = responseData['message'].toString();
      }
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Lỗi'),
          content: SingleChildScrollView(
            child: Text(errorMessage),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
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
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      children: [
                        const TextSpan(
                          text: 'Tổng số danh sách mã đang có: ',
                          style: TextStyle(color: Colors.blue),
                        ),
                        TextSpan(
                          text: '${_filteredItems.length}',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
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
                                final label = '${item['order']?['code'] ?? ''}_${item['order']?['total_quantity'] ?? ''}';
                                return ListTile(
                                  leading: const Icon(Icons.qr_code),
                                  title: Text(
                                    label,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
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