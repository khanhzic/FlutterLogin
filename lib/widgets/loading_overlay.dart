import 'package:flutter/material.dart';

class LoadingOverlay extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingText;
  final Color? backgroundColor;
  final Color? indicatorColor;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingText,
    this.backgroundColor,
    this.indicatorColor,
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isLoading)
          Container(
            color: widget.backgroundColor ?? Colors.black54,
            child: Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: widget.indicatorColor ?? Colors.blue,
                      ),
                      if (widget.loadingText != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          widget.loadingText!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Helper class để quản lý loading state
class LoadingManager extends ChangeNotifier {
  bool _isLoading = false;
  String? _loadingText;

  bool get isLoading => _isLoading;
  String? get loadingText => _loadingText;

  void showLoading([String? text]) {
    _isLoading = true;
    _loadingText = text;
    notifyListeners();
  }

  void hideLoading() {
    _isLoading = false;
    _loadingText = null;
    notifyListeners();
  }

  // Helper method để wrap API calls
  Future<T> withLoading<T>(
    Future<T> Function() apiCall, {
    String? loadingText,
  }) async {
    showLoading(loadingText);
    try {
      final result = await apiCall();
      return result;
    } finally {
      hideLoading();
    }
  }
} 