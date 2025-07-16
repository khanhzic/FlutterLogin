import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/api_common.dart';

class HandleDetailPage extends StatefulWidget {
  final String? code;
  final int? processId;
  const HandleDetailPage({Key? key, this.code, this.processId}) : super(key: key);

  @override
  State<HandleDetailPage> createState() => _HandleDetailPageState();
}

class _HandleDetailPageState extends State<HandleDetailPage> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  int get _quantity => int.tryParse(_quantityController.text) ?? 0;
  bool get _canComplete => _imageFile != null && _quantity > 0;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _onComplete() async {
    if (!_canComplete || widget.code == null || widget.processId == null) return;
    setState(() { _isLoading = true; });
    try {
      final respData = await ApiCommon.processAction(
        context: context,
        endpoint: 'end-working',
        data: {
          'order_code': widget.code!,
          'process_id': widget.processId!,
          'implement_quantity': _quantity,
          'total_quantity': 0,
          'note': _noteController.text,
        },
        image: _imageFile != null ? XFile(_imageFile!.path) : null,
      );
      if (respData['status'] == 'success') {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        _showErrorAlert(respData);
      }
    } on TokenExpiredException {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      _showErrorAlert({'message': 'Có lỗi không thể thực hiện. Hãy chụp màn hình và gửi cho admin'});
    } finally {
      setState(() { _isLoading = false; });
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
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  widget.code ?? 'Không có mã',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nhập số lượng',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 24),
              if (_imageFile != null)
                Column(
                  children: [
                    Image.file(_imageFile!, width: 180, height: 180, fit: BoxFit.cover),
                    const SizedBox(height: 8),
                  ],
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Chụp ảnh'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Chọn ảnh'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ElevatedButton(
                        onPressed: _canComplete && !_isLoading ? _onComplete : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Hoàn thành'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Tạm dừng'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF7F8FA),
    );
  }
} 