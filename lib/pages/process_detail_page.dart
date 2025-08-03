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
import '../services/products_service.dart';
import 'package:login_app/pages/handle_detail_page.dart'; // Import HandleDetailPage

class ProcessDetailPage extends StatefulWidget {
  final String processName;
  final int? processId;
  final String? initialOrderCode;
  final String? initialTotalQuantity;
  final String? initialImplementQuantity;
  final bool isContinue;

  const ProcessDetailPage({
    super.key,
    required this.processName,
    this.processId,
    this.initialOrderCode,
    this.initialTotalQuantity,
    this.initialImplementQuantity,
    this.isContinue = false,
  });

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
  String? _qrErrorMessage;
  String? _processingAction; // 'end', 'pending', or null
  String? _successMessage;
  String? _initialImplementQuantity;

  @override
  void initState() {
    super.initState();
    _qrCodeController.addListener(_updateStartButtonState);
    _quantityController.addListener(_updateStartButtonState);
    // Initialize controllers if values are provided
    if (widget.initialOrderCode != null) {
      _qrCodeController.text = widget.initialOrderCode!;
    }
    if (widget.initialTotalQuantity != null) {
      _quantityController.text = widget.initialTotalQuantity!;
    }
    // Optionally, you can store implement_quantity for use in API call
    if (widget.initialImplementQuantity != null) {
      // Store as a field if needed for API call
      _initialImplementQuantity = widget.initialImplementQuantity!;
    }
  }

  @override
  void dispose() {
    _qrCodeController.removeListener(_updateStartButtonState);
    _quantityController.removeListener(_updateStartButtonState);
    _qrCodeController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    controller?.dispose();
    super.dispose();
  }

  void _updateStartButtonState() {
    setState(() {
      final qrValid = _qrCodeController.text.isNotEmpty;
      _isStartButtonEnabled = qrValid;
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
        // Validate QR code format
        //if (ProductsService.isValidQRCode(qrData)) {
          setState(() {
            // _qrCodeController.text = qrData;
            try {
              final parseData = ProductsService.parseQRCode(qrData);
              int quantity = parseData["quantity"] ?? 0;
              String orderCode = parseData["orderCode"];

              _qrCodeController.text = '${orderCode}_$quantity';

              _isScanning = false;
              _qrErrorMessage = null;
            } catch (e) {
              //setState(() {
                _qrErrorMessage = MESSAGE_ERROR_QR_CODE;
              //});
            }
          });
        // } else {
        //   setState(() {
        //     _qrErrorMessage = MESSAGE_ERROR_QR_CODE;
        //     // Do NOT update _qrCodeController.text if invalid
        //   });
        // }
        // Always close scan screen after any scan
        controller.pauseCamera();
        Navigator.pop(context);
      }
    });
  }

  // bool _isValidQRCode(String qrData) {
  //   // Check if QR code matches format: <string>_<total_quantity>
  //   // Example: "ABC123_50" or "ORDER001_100"

  //   // Check if it contains exactly one underscore
  //   final parts = qrData.split('_');
  //   if (parts.length != 2) {
  //     return false;
  //   }

  //   final orderCode = parts[0];
  //   final quantityStr = parts[1];

  //   // Check if order code is not empty
  //   if (orderCode.isEmpty) {
  //     return false;
  //   }

  //   // Check if quantity is a valid number
  //   try {
  //     final quantity = int.parse(quantityStr);
  //     return quantity > 0; // Quantity must be positive
  //   } catch (e) {
  //     return false; // Quantity is not a valid number
  //   }
  // }

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
    _updateStartButtonState();
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

  Future<bool> _callApi(String endpoint, Map<String, dynamic> data,
      {XFile? image}) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final respData = await ApiCommon.processAction(
        context: context,
        endpoint: endpoint,
        data: data,
        image: image,
      );
      if (respData['status'] == "success") {
        return true;
      } else {
        _showErrorAlert(respData);
        return false;
      }
    } catch (e) {
      _showErrorAlert({
        'message':
            'Có lỗi xảy ra, hãy chụp lại màn hình và liên lạc với quản trị viên'
      });
      return false;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorAlert(Map<String, dynamic>? responseData) {
    String errorMessage =
        'Có lỗi xảy ra, hãy chụp lại màn hình và liên lạc với quản trị viên';

    if (responseData != null) {
      // Check if there are validation errors
      if (responseData['errors'] != null && responseData['errors'] is Map) {
        final errors = responseData['errors'] as Map<String, dynamic>;
        final errorMessages = <String>[];

        // Collect all error messages
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
        // Use the general message if no specific errors
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
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startProcess() async {
    FocusScope.of(context).unfocus(); // Hide keyboard
    int totalQuantity = 0;
    final qrText = _qrCodeController.text;
    final parts = qrText.split('_');
    if (parts.length == 2) {
      try {
        totalQuantity = int.parse(parts[1]);
      } catch (e) {}
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final respData = await ApiCommon.processAction(
        context: context,
        endpoint: 'start-working',
        data: {
          'order_code': parts[0],
          'process_id': widget.processId,
          'implement_quantity': 0,
          'total_quantity': totalQuantity,
        },
      );
      if (respData['status'] == 'success') {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        _showErrorAlert(respData);
      }
    } catch (e) {
      _showErrorAlert({
        'message':
            'Có lỗi xảy ra, hãy chụp lại màn hình và liên lạc với quản trị viên'
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _endProcess() async {
    setState(() {
      _processingAction = 'end';
    });
    int totalQuantity = 0;
    final qrText = _qrCodeController.text;
    final parts = qrText.split('_');
    if (parts.length == 2) {
      try {
        totalQuantity = int.parse(parts[1]);
      } catch (e) {}
    }
    final success = await _callApi('end-working', {
      'order_code': parts[0],
      'process_id': widget.processId,
      'implement_quantity': 0,
      'total_quantity': totalQuantity,
    });
    if (success) {
      setState(() {
        _processState = ProcessState.done;
        _successMessage = 'Đã cập nhật thành công!';
      });
    }
    setState(() {
      _processingAction = null;
    });
  }

  Future<void> _pendingProcess() async {
    setState(() {
      _processingAction = 'pending';
    });
    int totalQuantity = 0;
    final qrText = _qrCodeController.text;
    final parts = qrText.split('_');
    if (parts.length == 2) {
      try {
        totalQuantity = int.parse(parts[1]);
      } catch (e) {}
    }
    final result = await _showNoteAndImageDialog(
        'Nhập chú thích và chọn ảnh cho trạng thái dừng');
    if (result != null && result['note'] != null && result['image'] != null) {
      final success = await _callApi(
          'pending-working',
          {
            'order_code': parts[0],
            'process_id': widget.processId,
            'implement_quantity': 0,
            'total_quantity': totalQuantity,
            'note': result['note'],
          },
          image: result['image']);
      if (success && mounted) {
        setState(() {
          _successMessage = 'Đã cập nhật thành công!';
        });
        Navigator.of(context).pop();
      }
    }
    setState(() {
      _processingAction = null;
    });
  }

  Future<void> _stopProcess() async {
    final result = await _showNoteAndImageDialog(
        'Nhập chú thích và chọn ảnh cho trạng thái báo lỗi');
    if (result != null && result['note'] != null && result['image'] != null) {
      await _callApi(
          'work/stop',
          {
            'order_code': _qrCodeController.text,
            'process_id': widget.processId,
            'note': result['note'],
          },
          image: result['image']);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<Map<String, dynamic>?> _showNoteAndImageDialog(String title) async {
    final TextEditingController noteController = TextEditingController();
    XFile? pickedImage;
    bool canConfirm() =>
        noteController.text.trim().isNotEmpty && pickedImage != null;
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
                          final img = await ImagePicker()
                              .pickImage(source: ImageSource.camera);
                          if (img != null) setState(() => pickedImage = img);
                        },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Thư viện'),
                        onPressed: () async {
                          final img = await ImagePicker()
                              .pickImage(source: ImageSource.gallery);
                          if (img != null) setState(() => pickedImage = img);
                        },
                      ),
                    ],
                  ),
                  if (pickedImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('Đã chọn ảnh: ${pickedImage!.name}',
                          style: const TextStyle(fontSize: 13)),
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
                      ? () => Navigator.of(context).pop(
                          {'note': noteController.text, 'image': pickedImage})
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
              label: const Text('Quét mã QR sản phẩm'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            if (_qrErrorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                child: Text(
                  _qrErrorMessage!,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
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
            // Đã bỏ ô nhập số lượng sản phẩm thực hiện
            if (_successMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                child: Text(
                  _successMessage!,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 30),
            if (_processState == ProcessState.idle)
              ElevatedButton(
                onPressed:
                    _isStartButtonEnabled && !_isLoading ? _startProcess : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                  backgroundColor:
                      _isStartButtonEnabled ? Colors.blue : Colors.grey,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(widget.isContinue ? 'Tiếp tục' : 'Bắt đầu'),
              ),
            // Các nút khác đã được comment lại theo yêu cầu
            // if (_processState == ProcessState.started)
            //   ...
            // if (_processState == ProcessState.done)
            //   ...
            // if (_processState == ProcessState.pending)
            //   ...
            // if (_processState == ProcessState.error)
            //   ...
            // Các nút Hoàn thành, Dừng, loading khi đã bắt đầu đều đã comment lại
          ],
        ),
      ),
    );
  }
}
