import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
// Required for File
import 'package:login_app/pages/process_status_page.dart'; // Import the new page
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../services/api_common.dart';

class ProcessDetailPage extends StatefulWidget {
  final String processName;

  const ProcessDetailPage({super.key, required this.processName});

  @override
  State<ProcessDetailPage> createState() => _ProcessDetailPageState();
}

enum ProcessState { idle, started, done, pending, error }

class _ProcessDetailPageState extends State<ProcessDetailPage> {
  final TextEditingController _qrCodeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  bool _isStartButtonEnabled = false;
  XFile? _pickedImage; // Variable to store the picked image
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isScanning = false;
  ProcessState _processState = ProcessState.idle;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _qrCodeController.addListener(_updateStartButtonState);
  }

  @override
  void dispose() {
    _qrCodeController.removeListener(_updateStartButtonState);
    _qrCodeController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    controller?.dispose();
    super.dispose();
  }

  void _updateStartButtonState() {
    setState(() {
      _isStartButtonEnabled = _qrCodeController.text.isNotEmpty;
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
        setState(() {
          _qrCodeController.text = scanData.code!;
          _isScanning = false;
        });
        controller.pauseCamera();
        Navigator.pop(context);
      }
    });
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

  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    setState(() {
      _pickedImage = image;
    });

    if (image != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã chụp ảnh: ${image.name}')),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      _pickedImage = image;
    });

    if (image != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã chọn ảnh từ thư viện: ${image.name}')),
      );
    }
  }

  Future<void> _callApi(String endpoint, Map<String, dynamic> data, {XFile? image}) async {
    setState(() { _isLoading = true; });
    try {
      final respData = await ApiCommon.processAction(endpoint: endpoint, data: data, image: image);
      if (respData['success'] == true || respData['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thành công!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(respData['message'] ?? 'Lỗi')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _startProcess() async {
    await _callApi('work/start', {
      'order_code': _qrCodeController.text,
      'process_id': widget.processName, // You may want to map processName to an ID
      'total_quantity': _quantityController.text,
    });
    setState(() { _processState = ProcessState.started; });
  }

  Future<void> _endProcess() async {
    await _callApi('work/end', {
      'order_code': _qrCodeController.text,
      'process_id': widget.processName,
    });
    setState(() { _processState = ProcessState.done; });
  }

  Future<void> _pendingProcess() async {
    final result = await _showNoteAndImageDialog('Nhập chú thích và chọn ảnh cho trạng thái dừng');
    if (result != null && result['note'] != null && result['image'] != null) {
      await _callApi('work/pending', {
        'order_code': _qrCodeController.text,
        'process_id': widget.processName,
        'note': result['note'],
      }, image: result['image']);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _stopProcess() async {
    final result = await _showNoteAndImageDialog('Nhập chú thích và chọn ảnh cho trạng thái báo lỗi');
    if (result != null && result['note'] != null && result['image'] != null) {
      await _callApi('work/stop', {
        'order_code': _qrCodeController.text,
        'process_id': widget.processName,
        'note': result['note'],
      }, image: result['image']);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<Map<String, dynamic>?> _showNoteAndImageDialog(String title) async {
    final TextEditingController noteController = TextEditingController();
    XFile? pickedImage;
    bool canConfirm() => noteController.text.trim().isNotEmpty && pickedImage != null;
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Chú thích'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Máy ảnh'),
                        onPressed: () async {
                          final img = await ImagePicker().pickImage(source: ImageSource.camera);
                          if (img != null) setState(() => pickedImage = img);
                        },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Thư viện'),
                        onPressed: () async {
                          final img = await ImagePicker().pickImage(source: ImageSource.gallery);
                          if (img != null) setState(() => pickedImage = img);
                        },
                      ),
                    ],
                  ),
                  if (pickedImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('Đã chọn ảnh: ${pickedImage!.name}', style: const TextStyle(fontSize: 13)),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: canConfirm()
                      ? () => Navigator.of(context).pop({'note': noteController.text, 'image': pickedImage})
                      : null,
                  child: const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.processName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _scanQRCode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR Code'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _qrCodeController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Nội dung QR Code',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nhập số lượng sản phẩm sẽ làm',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
            // const SizedBox(height: 20),
            // TextField(
            //   controller: _notesController,
            //   decoration: const InputDecoration(
            //     labelText: 'Ghi chú',
            //     border: OutlineInputBorder(),
            //     prefixIcon: Icon(Icons.note_alt),
            //   ),
            //   maxLines: 3,
            //),
            const SizedBox(height: 30),
            if (_processState == ProcessState.idle)
              ElevatedButton(
                onPressed: _isStartButtonEnabled && !_isLoading ? _startProcess : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                  backgroundColor: _isStartButtonEnabled ? Colors.blue : Colors.grey,
                ),
                child: _isLoading ? const CircularProgressIndicator() : const Text('Bắt đầu'),
              ),
            if (_processState == ProcessState.started)
              Column(
                children: [
                  const SizedBox(
                    height: 48,
                    width: 48,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      strokeWidth: 6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: !_isLoading ? _endProcess : null,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: _isLoading ? const CircularProgressIndicator() : const Text('Hoàn thành'),
                      ),
                      ElevatedButton(
                        onPressed: !_isLoading ? _pendingProcess : null,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        child: _isLoading ? const CircularProgressIndicator() : const Text('Dừng'),
                      ),
                      // ElevatedButton(
                      //   onPressed: !_isLoading ? _stopProcess : null,
                      //   style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      //   child: _isLoading ? const CircularProgressIndicator() : const Text('Báo lỗi'),
                      // ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
} 