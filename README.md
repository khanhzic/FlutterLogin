Dưới đây là các command cơ bản để tạo, build và chạy một project Flutter mẫu ✅

⸻

🔹 1. Kiểm tra môi trường

flutter doctor


⸻

🔹 2. Tạo project Flutter mới

flutter create my_app

Vào project:

cd my_app


⸻

🔹 3. Chạy project ở chế độ debug

(trên thiết bị đã kết nối hoặc emulator đang mở)

flutter run


⸻

🔹 4. Chạy với platform chỉ định

Android:

flutter run -d android

iOS (macOS only):

flutter run -d ios

Web:

flutter run -d chrome


⸻

🔹 5. Build app

✅ Android APK

flutter build apk

APK sau khi build:

build/app/outputs/flutter-apk/app-release.apk

✅ Android App Bundle (Google Play)

flutter build appbundle

File output:

build/app/outputs/bundle/release/app-release.aab

✅ iOS (macOS required)

flutter build ios

✅ Web

flutter build web


⸻

🔹 6. Clean project (khi lỗi build)

flutter clean
flutter pub get


⸻

🔹 7. Update dependencies

flutter pub get

Hoặc nâng cấp deps:

flutter pub upgrade


⸻

🔹 8. Kiểm tra thiết bị đang kết nối

flutter devices


⸻

✅ Tóm tắt nhanh

Công việc	Command
Tạo project	flutter create my_app
Chạy app	flutter run
Build APK	flutter build apk
Build AAB	flutter build appbundle
Clean	flutter clean
Cài dependencies	flutter pub get
Kiểm tra thiết bị	flutter devices


⸻

Nếu bạn muốn mình có thể tạo giúp bạn sẵn:
✅ UI mẫu (login, home, list, dashboard…)
✅ Cấu trúc thư mục chuẩn
✅ State management
✅ API connect mẫu

Bạn muốn mình gen template nào không? 😎