# LoadingOverlay System

Hệ thống LoadingOverlay được tạo để tự động hiển thị loading indicator khi gọi API từ `ApiCommon`.

## Cách sử dụng

### 1. Tạo LoadingManager trong Widget

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final LoadingManager _loadingManager = LoadingManager();

  @override
  void initState() {
    super.initState();
    // Khởi tạo LoadingManager cho ApiCommon
    ApiCommon.setLoadingManager(_loadingManager);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _loadingManager,
      builder: (context, child) {
        return LoadingOverlay(
          isLoading: _loadingManager.isLoading,
          loadingText: _loadingManager.loadingText,
          child: Scaffold(
            // Your scaffold content
          ),
        );
      },
    );
  }
}
```

### 2. Gọi API

Khi bạn gọi bất kỳ API nào từ `ApiCommon`, loading overlay sẽ tự động hiển thị:

```dart
// Loading overlay sẽ tự động hiển thị
final result = await ApiCommon.getUserReport();

// Hoặc với custom loading text
final result = await ApiCommon.login(email, password);
```

### 3. Các API đã được tích hợp

- `ApiCommon.login()` - Hiển thị "Đang đăng nhập..."
- `ApiCommon.changePassword()` - Hiển thị "Đang đổi mật khẩu..."
- `ApiCommon.getUserReport()` - Hiển thị "Đang tải dữ liệu..."
- `ApiCommon.post()` - Hiển thị "Đang xử lý..."
- `ApiCommon.multipartPost()` - Hiển thị "Đang tải lên..."

### 4. Tùy chỉnh LoadingOverlay

```dart
LoadingOverlay(
  isLoading: _loadingManager.isLoading,
  loadingText: _loadingManager.loadingText,
  backgroundColor: Colors.black54, // Tùy chỉnh màu nền
  indicatorColor: Colors.blue,     // Tùy chỉnh màu indicator
  child: YourWidget(),
)
```

### 5. Sử dụng LoadingManager trực tiếp

Bạn cũng có thể sử dụng LoadingManager trực tiếp:

```dart
// Hiển thị loading với text tùy chỉnh
_loadingManager.showLoading('Đang xử lý...');

// Ẩn loading
_loadingManager.hideLoading();

// Hoặc wrap API call
final result = await _loadingManager.withLoading(
  () => yourApiCall(),
  loadingText: 'Đang tải dữ liệu...',
);
```

## Ví dụ hoàn chỉnh

Xem file `lib/pages/demo_loading_page.dart` để có ví dụ hoàn chỉnh về cách sử dụng.

## Lưu ý

- LoadingOverlay sẽ hiển thị một overlay mờ với CircularProgressIndicator ở giữa
- Text loading sẽ hiển thị bên dưới indicator
- Overlay sẽ tự động ẩn khi API call hoàn thành (thành công hoặc lỗi)
- Mỗi Widget cần có một LoadingManager riêng nếu muốn quản lý loading state độc lập 