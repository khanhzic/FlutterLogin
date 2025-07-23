import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/loading_overlay.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/material.dart';

class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException([this.message = 'Token đã hết hạn']);
  @override
  String toString() => message;
}

class ApiCommon {
  static LoadingManager? _loadingManager;
  static const String _tokenKey = 'access_token';

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
        throw TokenExpiredException();
      }
      return onSuccess(response);
    } on TokenExpiredException {
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
          final response = await http.post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          ).timeout(const Duration(seconds: 60), onTimeout: () {
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
    ) ?? _loginWithoutLoading(email, password);
  }

  static Future<Map<String, dynamic>> _loginWithoutLoading(String email, String password) async {
    final url = '$baseUrl/login';
    final headers = {'Content-Type': 'application/json'};
    final body = {'email': email, 'password': password};
    
    _logRequest('POST', url, headers, body);
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 60), onTimeout: () {
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

  static Future<Map<String, dynamic>> multipartPost(BuildContext context, String endpoint, Map<String, dynamic> data, XFile image, {Map<String, String>? headers}) {
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
      onSuccess: (response) => jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static Future<Map<String, dynamic>> _multipartPostWithoutLoading(String endpoint, Map<String, dynamic> data, XFile image, {Map<String, String>? headers}) async {
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

  static Future<Map<String, dynamic>> startTransport(List<String> productCodes) async {
    final token = await getToken();
    final url = '$baseUrl/delivery/start/';
    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final body = {
      'item_codes': productCodes,
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

  static Future<List<Map<String, dynamic>>> getListDeliveryItems() async {
    final token = await getToken();
    final url = '$baseUrl/delivery/list';
    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    _logRequest('GET', url, headers, null);
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      _logResponse('GET', url, response.statusCode, response.headers, response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      _logError('GET', url, e);
      rethrow;
    }
  }
} 