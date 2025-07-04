import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
// Required for File
import 'package:login_app/pages/process_status_page.dart'; // Import the new page
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class ProcessDetailPage extends StatefulWidget {
  final String processName;

  const ProcessDetailPage({super.key, required this.processName});

  @override
  State<ProcessDetailPage> createState() => _ProcessDetailPageState();
}

class _ProcessDetailPageState extends State<ProcessDetailPage> {
  final TextEditingController _qrCodeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  bool _isStartButtonEnabled = false;
  XFile? _pickedImage; // Variable to store the picked image
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isScanning = false;

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

  void _startProcess() {
    // Instead of showing a SnackBar, navigate to the new ProcessStatusPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProcessStatusPage(processName: widget.processName),
      ),
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
            const SizedBox(height: 20),
            // TextField(
            //   controller: _notesController,
            //   decoration: const InputDecoration(
            //     labelText: 'Ghi chú',
            //     border: OutlineInputBorder(),
            //     prefixIcon: Icon(Icons.note_alt),
            //   ),
            //   maxLines: 3,
            // ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isStartButtonEnabled ? _startProcess : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: _isStartButtonEnabled ? Colors.blue : Colors.grey,
              ),
              child: const Text('START'),
            ),
          ],
        ),
      ),
    );
  }
} 