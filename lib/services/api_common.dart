import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:login_app/models/delivery_items.dart';
import 'package:login_app/models/order_code.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/loading_overlay.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/material.dart';
import '../main.dart';

class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException([this.message = 'Token đã hết hạn']);
  @override
  String toString() => message;
}

class ApiCommon {
  static LoadingManager? _loadingManager;
  static const String _tokenKey = 'access_token';
  static const String _deliveryListCode = "delivery_list_code";

  // Setter để inject LoadingManager
  static void setLoadingManager(LoadingManager manager) {
    _loadingManager = manager;
  }

  // Logging utility methods
  static void _logRequest(String method, String url, Map<String, String> headers, dynamic body) {
    print('🌐 API REQUEST:');
    print('   Method: $method');
    print('   URL: $url');
    print('   Headers: ${jsonEncode(headers)}');
    if (body != null) {
      print('   Body: ${jsonEncode(body)}');
    }
    print('   Timestamp: ${DateTime.now().toIso8601String()}');
  }

  static void _logResponse(String method, String url, int statusCode, Map<String, String> headers, String body) {
    print('📡 API RESPONSE:');
    print('   Method: $method');
    print('   URL: $url');
    print('   Status Code: $statusCode');
    print('   Headers: ${jsonEncode(headers)}');
    print('   Body: $body');
    print('   Timestamp: ${DateTime.now().toIso8601String()}');
  }

  static void _logError(String method, String url, dynamic error) {
    print('❌ API ERROR:');
    print('   Method: $method');
    print('   URL: $url');
    print('   Error: $error');
    print('   Timestamp: ${DateTime.now().toIso8601String()}');
  }

  // Get token from cache
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Store token in cache
  static Future<void> storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Clear token from cache
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Kiểm tra token hết hạn (JWT)
  static Future<bool> isTokenExpired() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return true;
    try {
      return JwtDecoder.isExpired(token);
    } catch (e) {
      // Nếu token không phải JWT hoặc lỗi giải mã, coi như hết hạn
      return true;
    }
  }

  /// Kiểm tra token hết hạn, nếu hết hạn thì xóa token, user và chuyển về màn hình login
  static Future<void> checkAndHandleTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty || JwtDecoder.isExpired(token)) {
      await prefs.remove(_tokenKey);
      await prefs.remove('user');
      throw TokenExpiredException();
    }
  }

  /// Hàm generic kiểm tra token hết hạn trước khi gọi API
  static Future<T> withTokenCheck<T>(BuildContext context, Future<T> Function() apiCall) async {
    try {
      await checkAndHandleTokenExpired();
      return await apiCall();
    } on TokenExpiredException {
      if (T == Map<String, dynamic>) {
        return <String, dynamic>{} as T;
      }
      throw Exception('Token expired');
    }
  }

  /// Hàm generic kiểm tra token hết hạn và status 401 cho mọi API
  static Future<T> safeApiCall<T>({
    required BuildContext context,
    required Future<http.Response> Function() apiRequest,
    required T Function(http.Response) onSuccess,
  }) async {
    try {
      await checkAndHandleTokenExpired();
      final response = await apiRequest();
      if (response.statusCode == 401) {
        await clearToken();
        // Tự động redirect về login khi token hết hạn
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
        throw TokenExpiredException();
      }
      return onSuccess(response);
    } on TokenExpiredException {
      // Tự động redirect về login khi token hết hạn
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    return _loadingManager?.withLoading(
          () async {
            final url = '$baseUrl/login';
            final headers = {'Content-Type': 'application/json'};
            final body = {'email': email, 'password': password};

            _logRequest('POST', url, headers, body);

            try {
              final response = await http
                  .post(
                Uri.parse(url),
                headers: headers,
                body: jsonEncode(body),
              )
                  .timeout(const Duration(seconds: 60), onTimeout: () {
                throw Exception('Kết nối quá lâu, vui lòng thử lại.');
              });

              _logResponse('POST', url, response.statusCode, response.headers, response.body);

              final data = jsonDecode(response.body);

              // Store token in cache if login is successful
              if (data.containsKey('access_token')) {
                await storeToken(data['access_token']);
              }

              return data;
            } catch (e) {
              _logError('POST', url, e);
              rethrow;
            }
          },
          loadingText: 'Đang đăng nhập...',
        ) ??
        _loginWithoutLoading(email, password);
  }

  static Future<Map<String, dynamic>> _loginWithoutLoading(String email, String password) async {
    final url = '$baseUrl/login';
    final headers = {'Content-Type': 'application/json'};
    final body = {'email': email, 'password': password};

    _logRequest('POST', url, headers, body);

    try {
      final response = await http
          .post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 60), onTimeout: () {
        throw Exception('Kết nối quá lâu, vui lòng thử lại.');
      });

      _logResponse('POST', url, response.statusCode, response.headers, response.body);

      final data = jsonDecode(response.body);

      // Store token in cache if login is successful
      if (data.containsKey('access_token')) {
        await storeToken(data['access_token']);
      }

      return data;
    } catch (e) {
      _logError('POST', url, e);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> changePassword(BuildContext context, String oldPassword, String newPassword, String confirmPassword) {
    return safeApiCall(
      context: context,
      apiRequest: () async {
        final token = await getToken();
        final url = '$baseUrl/users/change-password';
        final headers = {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        };
        final body = {
          'old_password': oldPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmPassword,
        };
        _logRequest('POST', url, headers, body);
        return await http.post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(body),
        );
      },
      onSuccess: (response) => jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static Future<Map<String, dynamic>> _changePasswordWithoutLoading(String oldPassword, String newPassword, String confirmPassword) async {
    if (await isTokenExpired()) {
      await clearToken();
      throw Exception('Token đã hết hạn. Vui lòng đăng nhập lại.');
    }
    final token = await getToken();
    final url = '$baseUrl/api/v1/users/change-password';
    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final body = {
      'old_password': oldPassword,
      'new_password': newPassword,
      'new_password_confirmation': confirmPassword,
    };

    _logRequest('POST', url, headers, body);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      _logResponse('POST', url, response.statusCode, response.headers, response.body);

      return jsonDecode(response.body);
    } catch (e) {
      _logError('POST', url, e);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> post(BuildContext context, String endpoint, Map<String, dynamic> data, {Map<String, String>? headers}) {
    return safeApiCall(
      context: context,
      apiRequest: () async {
        final token = await getToken();
        final url = '$baseUrl/$endpoint';
        final requestHeaders = {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
          ...?headers,
        };
        _logRequest('POST', url, requestHeaders, data);
        return await http.post(
          Uri.parse(url),
          headers: requestHeaders,
          body: jsonEncode(data),
        );
      },
      onSuccess: (response) => jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static Future<Map<String, dynamic>> _postWithoutLoading(String endpoint, Map<String, dynamic> data, {Map<String, String>? headers}) async {
    if (await isTokenExpired()) {
      await clearToken();
      throw Exception('Token đã hết hạn. Vui lòng đăng nhập lại.');
    }
    final token = await getToken();
    final url = '$baseUrl/$endpoint';
    final requestHeaders = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?headers,
    };

    _logRequest('POST', url, requestHeaders, data);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: requestHeaders,
        body: jsonEncode(data),
      );

      _logResponse('POST', url, response.statusCode, response.headers, response.body);

      return jsonDecode(response.body);
    } catch (e) {
      _logError('POST', url, e);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> multipartPost(BuildContext context, String endpoint, Map<String, dynamic> data, XFile image,
      {Map<String, String>? headers}) {
    return safeApiCall(
      context: context,
      apiRequest: () async {
        final token = await getToken();
        final url = '$baseUrl/$endpoint';

        print('🌐 API MULTIPART REQUEST:');
        print('   Method: POST');
        print('   URL: $url');
        print('   Data: ${jsonEncode(data)}');
        print('   Image: ${image.path}');
        print('   Timestamp: ${DateTime.now().toIso8601String()}');

        var request = http.MultipartRequest('POST', Uri.parse(url));
        request.fields.addAll(data.map((k, v) => MapEntry(k, v.toString())));
        request.files.add(await http.MultipartFile.fromPath('file_upload', image.path));
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
        if (headers != null) request.headers.addAll(headers);

        var streamed = await request.send();
        return await http.Response.fromStream(streamed);
      },
      onSuccess: (response) {
        print('🔍 DEBUG: Response status code: ${response.statusCode}');
        print('🔍 DEBUG: Response body: ${response.body}');
        return jsonDecode(response.body) as Map<String, dynamic>;
      },
    );
  }

  static Future<Map<String, dynamic>> _multipartPostWithoutLoading(String endpoint, Map<String, dynamic> data, XFile image,
      {Map<String, String>? headers}) async {
    if (await isTokenExpired()) {
      await clearToken();
      throw Exception('Token đã hết hạn. Vui lòng đăng nhập lại.');
    }
    final token = await getToken();
    final url = '$baseUrl/$endpoint';

    print('🌐 API MULTIPART REQUEST:');
    print('   Method: POST');
    print('   URL: $url');
    print('   Data: ${jsonEncode(data)}');
    print('   Image: ${image.path}');
    print('   Timestamp: ${DateTime.now().toIso8601String()}');

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields.addAll(data.map((k, v) => MapEntry(k, v.toString())));
      request.files.add(await http.MultipartFile.fromPath('file_upload', image.path));
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      if (headers != null) request.headers.addAll(headers);

      var streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      _logResponse('POST (Multipart)', url, response.statusCode, response.headers, response.body);

      return jsonDecode(response.body);
    } catch (e) {
      _logError('POST (Multipart)', url, e);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> processAction({
    required BuildContext context,
    required String endpoint,
    required Map<String, dynamic> data,
    XFile? image,
    Map<String, String>? headers,
  }) async {
    if (image != null) {
      return await multipartPost(context, endpoint, data, image, headers: headers);
    } else {
      return await post(context, endpoint, data, headers: headers);
    }
  }

  static Future<Map<String, dynamic>?> getUserReport(BuildContext context) {
    return safeApiCall(
      context: context,
      apiRequest: () async {
        final token = await getToken();
        final url = '$baseUrl/report/report-by-user';
        final headers = {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        };
        _logRequest('GET', url, headers, null);
        return await http.get(Uri.parse(url), headers: headers);
      },
      onSuccess: (response) => response.statusCode == 200 ? jsonDecode(response.body) as Map<String, dynamic> : <String, dynamic>{},
    );
  }

  static Future<Map<String, dynamic>?> _getUserReportWithoutLoading() async {
    if (await isTokenExpired()) {
      await clearToken();
      throw Exception('Token đã hết hạn. Vui lòng đăng nhập lại.');
    }
    final token = await getToken();
    final url = '$baseUrl/report/report-by-user';
    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    _logRequest('GET', url, headers, null);

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      _logResponse('GET', url, response.statusCode, response.headers, response.body);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      _logError('GET', url, e);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserData(BuildContext context) {
    return safeApiCall(
      context: context,
      apiRequest: () async {
        final token = await getToken();
        final url = '$baseUrl/me';
        final headers = {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        };
        _logRequest('GET', url, headers, null);
        return await http.get(Uri.parse(url), headers: headers);
      },
      onSuccess: (response) => response.statusCode == 200 ? jsonDecode(response.body) as Map<String, dynamic> : <String, dynamic>{},
    );
  }

  static Future<Map<String, dynamic>?> _getUserDataWithoutLoading() async {
    if (await isTokenExpired()) {
      await clearToken();
      throw Exception('Token đã hết hạn. Vui lòng đăng nhập lại.');
    }
    final token = await getToken();
    final url = '$baseUrl/me';
    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    _logRequest('GET', url, headers, null);

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      _logResponse('GET', url, response.statusCode, response.headers, response.body);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      _logError('GET', url, e);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getMasterData(BuildContext context) {
    return safeApiCall(
      context: context,
      apiRequest: () async {
        final token = await getToken();
        final url = '$baseUrl/get-master-data';
        final headers = {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        };
        _logRequest('GET', url, headers, null);
        return await http.get(Uri.parse(url), headers: headers);
      },
      onSuccess: (response) => response.statusCode == 200 ? jsonDecode(response.body) as Map<String, dynamic> : <String, dynamic>{},
    );
  }

  static Future<Map<String, dynamic>?> _getMasterDataWithoutLoading() async {
    if (await isTokenExpired()) {
      await clearToken();
      throw Exception('Token đã hết hạn. Vui lòng đăng nhập lại.');
    }
    final token = await getToken();
    final url = '$baseUrl/get-master-data';
    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    _logRequest('GET', url, headers, null);

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      _logResponse('GET', url, response.statusCode, response.headers, response.body);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      _logError('GET', url, e);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> startTransport(BuildContext context, List<String> productCodes, List<OrderCode> qrcodes) {
    return safeApiCall(
      context: context,
      apiRequest: () async {
        final token = await getToken();
        final url = '$baseUrl/delivery/start';
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };

        print('🔍 DEBUG: startTransport - Starting...');
        print('🔍 DEBUG: - productCodes: $productCodes');
        print('🔍 DEBUG: - qrcodes length: ${qrcodes.length}');
        for (int i = 0; i < qrcodes.length; i++) {
          print('🔍 DEBUG: - qrcodes[$i]: orderCode=${qrcodes[i].orderCode}, quantity=${qrcodes[i].quantity}, qrData="${qrcodes[i].qrData}"');
        }

        final body = {
          'item_codes': productCodes,
          'qrcodes': qrcodes,
        };

        print('🔍 DEBUG: - Request body: ${jsonEncode(body)}');

        _logRequest('POST', url, headers, body);
        return await http.post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(body),
        );
      },
      onSuccess: (response) => jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static Future<List<Map<String, dynamic>>> getListDeliveryItems(BuildContext context) {
    return safeApiCall(
      context: context,
      apiRequest: () async {
        final token = await getToken();
        final url = '$baseUrl/delivery/list';
        final headers = {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        };
        _logRequest('POST', url, headers, null);
        return await http.post(Uri.parse(url), headers: headers);
      },
      onSuccess: (response) {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('🔍 DEBUG: API Response data: $data');
          print('🔍 DEBUG: data["status"]: ${data['status']}');
          print('🔍 DEBUG: data["data"] is List: ${data['data'] is List}');
          print('🔍 DEBUG: data["data"] length: ${data['data'] is List ? (data['data'] as List).length : 'not a list'}');

          if (data['status'] == 'success' && data['data'] is List) {
            // Convert to List<DeliveryItems>
            final deliveryItemsList = (data['data'] as List).map((item) => DeliveryItems.fromJson(item as Map<String, dynamic>)).toList();
            print('🔍 DEBUG: Final processed DeliveryItems length: ${deliveryItemsList.length}');
            print('🔍 DEBUG: First DeliveryItems: ${deliveryItemsList.isNotEmpty ? deliveryItemsList.first : 'empty'}');

            // update list delivery items cache
            storeDeliveryList(deliveryItemsList);

            // Optionally, return the original data or the model list
            return <Map<String, dynamic>>[];
          }
        }
        print('🔍 DEBUG: Returning empty list');
        return <Map<String, dynamic>>[];
      },
    );
  }

  // deliveries list cache
  // return {
  //       'orderCode': orderCode,
  //       'quantity': quantity,
  //     };
  static Future<List<OrderCode>> getDeliveryListFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_deliveryListCode);

    print('🔍 DEBUG: getDeliveryListFromCache - Starting...');
    print('🔍 DEBUG: jsonString is null: ${jsonString == null}');
    print('🔍 DEBUG: jsonString is empty: ${jsonString?.isEmpty ?? true}');
    print('🔍 DEBUG: jsonString content: "$jsonString"');

    if (jsonString == null) {
      print('🔍 DEBUG: Cache is null, returning empty list');
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      print('🔍 DEBUG: Successfully decoded JSON, found ${decoded.length} items');

      List<OrderCode> result = [];

      // Parse từng item một cách an toàn
      for (int i = 0; i < decoded.length; i++) {
        var item = decoded[i];
        print('🔍 DEBUG: Processing item $i: $item');
        try {
          if (item is Map<String, dynamic>) {
            OrderCode orderCode = OrderCode.fromJson(item);
            result.add(orderCode);
            print('🔍 DEBUG: Successfully parsed item $i: orderCode=${orderCode.orderCode}, quantity=${orderCode.quantity}');
          } else {
            print('🔍 ERROR: Item $i is not Map<String, dynamic>, type: ${item.runtimeType}');
          }
        } catch (parseError) {
          print('🔍 ERROR: Failed to parse item $i: $parseError');
          print('🔍 ERROR: Item data: $item');
        }
      }

      // Debug log để kiểm tra dữ liệu
      print('🔍 DEBUG: getDeliveryListFromCache - Final result: ${result.length} items:');
      for (int i = 0; i < result.length; i++) {
        print('🔍 DEBUG: Item $i: orderCode=${result[i].orderCode}, quantity=${result[i].quantity}, qrData="${result[i].qrData}"');
      }

      return result;
    } catch (e) {
      print('🔍 ERROR: Failed to parse delivery list from cache: $e');
      print('🔍 ERROR: JSON string: $jsonString');
      // Nếu có lỗi parse, xóa cache và trả về list rỗng
      await prefs.remove(_deliveryListCode);
      print('🔍 DEBUG: Cleared corrupted cache data');
      return [];
    }
  }

  // Store token in cache
  static Future<void> storeDeliveryList(List<DeliveryItems> dataList) async {
    final prefs = await SharedPreferences.getInstance();
    List<OrderCode> data = [];
    for (var item in dataList) {
      print('🔍 DEBUG: Creating OrderCode from server data:');
      print('🔍 DEBUG: - orderCode: ${item.order.code}');
      print('🔍 DEBUG: - quantity: ${item.order.totalQuantity}');
      print('🔍 DEBUG: - qrData (notes): ${item.order.notes}');

      // Chỉ sử dụng notes từ server nếu không rỗng
      String qrData = item.order.notes.isNotEmpty ? item.order.notes : "";

      OrderCode orderCode = new OrderCode(orderCode: item.order.code, quantity: item.order.totalQuantity, qrData: qrData);
      data.add(orderCode); // Append to list
    }

    try {
      final jsonString = jsonEncode(data); // convert to JSON string
      await prefs.setString(_deliveryListCode, jsonString);
      print('🔍 DEBUG: Successfully stored delivery list to cache');
    } catch (e) {
      print('🔍 ERROR: Failed to encode delivery list to JSON: $e');
      // Nếu có lỗi encode, thử encode từng item riêng lẻ
      List<Map<String, dynamic>> safeData = [];
      for (var item in data) {
        try {
          safeData.add(item.toJson());
        } catch (itemError) {
          print('🔍 ERROR: Failed to encode item ${item.orderCode}: $itemError');
        }
      }
      if (safeData.isNotEmpty) {
        try {
          final safeJsonString = jsonEncode(safeData);
          await prefs.setString(_deliveryListCode, safeJsonString);
          print('🔍 DEBUG: Successfully stored safe delivery list to cache');
        } catch (finalError) {
          print('🔍 ERROR: Failed to encode safe delivery list: $finalError');
        }
      }
    }
  }

  static Future<void> addItemToDeliveryList(OrderCode newItem) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_deliveryListCode);

    print('🔍 DEBUG: addItemToDeliveryList - Starting...');
    print('🔍 DEBUG: - orderCode: ${newItem.orderCode}');
    print('🔍 DEBUG: - quantity: ${newItem.quantity}');
    print('🔍 DEBUG: - qrData (scanned): ${newItem.qrData}');
    print('🔍 DEBUG: - jsonString is null: ${jsonString == null}');
    print('🔍 DEBUG: - jsonString is empty: ${jsonString?.isEmpty ?? true}');
    print('🔍 DEBUG: - jsonString content: "$jsonString"');

    if (jsonString == null || jsonString.isEmpty || jsonString == '[]') {
      print('🔍 DEBUG: Cache is empty or null, creating new list with scanned item');
      List<OrderCode> newList = [newItem];
      final newJsonString = jsonEncode(newList);
      await prefs.setString(_deliveryListCode, newJsonString);
      print('🔍 DEBUG: Successfully created new cache with scanned item');
      return;
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      print('🔍 DEBUG: Successfully decoded existing cache, found ${decoded.length} items');

      List<OrderCode> currentList = [];

      // Parse từng item một cách an toàn
      for (int i = 0; i < decoded.length; i++) {
        var item = decoded[i];
        print('🔍 DEBUG: Processing existing item $i: $item');
        try {
          if (item is Map<String, dynamic>) {
            OrderCode orderCode = OrderCode.fromJson(item);
            currentList.add(orderCode);
            print('🔍 DEBUG: Successfully parsed existing item $i: orderCode=${orderCode.orderCode}, quantity=${orderCode.quantity}');
          } else {
            print('🔍 ERROR: Existing item $i is not Map<String, dynamic>, type: ${item.runtimeType}');
          }
        } catch (parseError) {
          print('🔍 ERROR: Failed to parse existing item $i: $parseError');
          print('🔍 ERROR: Item data: $item');
        }
      }

      // Kiểm tra xem item đã tồn tại chưa
      bool itemExists = false;
      for (int i = 0; i < currentList.length; i++) {
        if (currentList[i].orderCode == newItem.orderCode) {
          // Cập nhật qrData nếu item đã tồn tại
          currentList[i] = OrderCode(
            orderCode: currentList[i].orderCode,
            quantity: currentList[i].quantity,
            qrData: newItem.qrData, // Cập nhật với qrData mới từ scan
          );
          itemExists = true;
          print('🔍 DEBUG: Updated existing item with new qrData');
          break;
        }
      }

      if (!itemExists) {
        currentList.add(newItem);
        print('🔍 DEBUG: Added new item to delivery list');
      }

      // Lưu lại vào cache
      final updatedJsonString = jsonEncode(currentList);
      await prefs.setString(_deliveryListCode, updatedJsonString);
      print('🔍 DEBUG: Successfully saved updated delivery list to cache');
      print('🔍 DEBUG: Final cache content: $updatedJsonString');
    } catch (e) {
      print('🔍 ERROR: Failed to parse delivery list from cache: $e');
      print('🔍 ERROR: JSON string: $jsonString');
      // Nếu có lỗi parse, xóa cache và tạo mới
      await prefs.remove(_deliveryListCode);
      print('🔍 DEBUG: Cleared corrupted cache data');

      // Tạo cache mới với item hiện tại
      List<OrderCode> newList = [newItem];
      final newJsonString = jsonEncode(newList);
      await prefs.setString(_deliveryListCode, newJsonString);
      print('🔍 DEBUG: Created new cache with scanned item after clearing corrupted data');
    }
  }

  // Clear token from cache
  static Future<void> removeItemToDeliveryList(dynamic code) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_deliveryListCode);

    if (jsonString != null) {
      try {
        List<dynamic> decodedList = jsonDecode(jsonString);
        List<Map<String, dynamic>> updatedList = [];

        for (var item in decodedList) {
          try {
            if (item is Map<String, dynamic> && item['orderCode'] != code) {
              updatedList.add(Map<String, dynamic>.from(item));
            }
          } catch (parseError) {
            print('🔍 ERROR: Failed to parse item in removeItemToDeliveryList: $parseError');
          }
        }

        await prefs.setString(_deliveryListCode, jsonEncode(updatedList));
        print('🔍 DEBUG: Successfully removed item with code: $code');
      } catch (e) {
        print('🔍 ERROR: Failed to remove item from delivery list: $e');
        print('🔍 ERROR: JSON string: $jsonString');
        // Nếu có lỗi, xóa cache
        await prefs.remove(_deliveryListCode);
        print('🔍 DEBUG: Cleared corrupted cache data');
      }
    }
  }

  static Future<void> clearDeliveryListFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(_deliveryListCode);
  }

  static Future<DeliveryItems?> existedItemOnDeliveryList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_deliveryListCode);

    if (jsonString == null) return null;

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      final List<DeliveryItems> decodedList = decoded.map((item) => DeliveryItems.fromJson(item as Map<String, dynamic>)).toList();
      // final List<DeliveryItems> decodedList = jsonDecode(jsonString);
      for (var item in decodedList) {
        if (item.order.code == key) {
          return item;
        }
      }
    } catch (e) {
      print('🔍 ERROR: Failed to check item existence: $e');
      print('🔍 ERROR: JSON string: $jsonString');
      // Nếu có lỗi, xóa cache và trả về false
      await prefs.remove(_deliveryListCode);
      print('🔍 DEBUG: Cleared corrupted cache data');
      return null;
    }

    // List<Map<String, dynamic>> updatedList = decodedList.map((e) => Map<String, dynamic>.from(e)).where((item) => item['orderCode'] == key).toList();

    // if (updatedList.isNotEmpty && updatedList.length > 0) {
    //   return true;
    // }

    return null;
  }
}
