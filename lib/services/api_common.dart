import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/loading_overlay.dart';

class ApiCommon {
  static LoadingManager? _loadingManager;
  static const String _tokenKey = 'access_token';

  // Setter để inject LoadingManager
  static void setLoadingManager(LoadingManager manager) {
    _loadingManager = manager;
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

  static Future<Map<String, dynamic>> login(String email, String password) async {
    return _loadingManager?.withLoading(
      () async {
        final response = await http.post(
          Uri.parse('$baseUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        ).timeout(const Duration(seconds: 60), onTimeout: () {
          throw Exception('Kết nối quá lâu, vui lòng thử lại.');
        });
        
        final data = jsonDecode(response.body);
        
        // Store token in cache if login is successful
        if (data.containsKey('access_token')) {
          await storeToken(data['access_token']);
        }
        
        return data;
      },
      loadingText: 'Đang đăng nhập...',
    ) ?? _loginWithoutLoading(email, password);
  }

  static Future<Map<String, dynamic>> _loginWithoutLoading(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 60), onTimeout: () {
      throw Exception('Kết nối quá lâu, vui lòng thử lại.');
    });
    
    final data = jsonDecode(response.body);
    
    // Store token in cache if login is successful
    if (data.containsKey('access_token')) {
      await storeToken(data['access_token']);
    }
    
    return data;
  }

  static Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword, String confirmPassword) async {
    return _loadingManager?.withLoading(
      () async {
        final token = await getToken();
        final url = Uri.parse('$baseUrl/users/change_password');
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'old_password': oldPassword,
            'new_password': newPassword,
            'new_password_confirmation': confirmPassword,
          }),
        );
        return jsonDecode(response.body);
      },
      loadingText: 'Đang đổi mật khẩu...',
    ) ?? _changePasswordWithoutLoading(oldPassword, newPassword, confirmPassword);
  }

  static Future<Map<String, dynamic>> _changePasswordWithoutLoading(String oldPassword, String newPassword, String confirmPassword) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/users/change_password');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data, {Map<String, String>? headers}) async {
    return _loadingManager?.withLoading(
      () async {
        final token = await getToken();
        final url = Uri.parse('$baseUrl/$endpoint');
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
            ...?headers,
          },
          body: jsonEncode(data),
        );
        return jsonDecode(response.body);
      },
      loadingText: 'Đang xử lý...',
    ) ?? _postWithoutLoading(endpoint, data, headers: headers);
  }

  static Future<Map<String, dynamic>> _postWithoutLoading(String endpoint, Map<String, dynamic> data, {Map<String, String>? headers}) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/$endpoint');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        ...?headers,
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> multipartPost(String endpoint, Map<String, dynamic> data, XFile image, {Map<String, String>? headers}) async {
    return _loadingManager?.withLoading(
      () async {
        final token = await getToken();
        final url = Uri.parse('$baseUrl/$endpoint');
        var request = http.MultipartRequest('POST', url);
        request.fields.addAll(data.map((k, v) => MapEntry(k, v.toString())));
        request.files.add(await http.MultipartFile.fromPath('evident', image.path));
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
        if (headers != null) request.headers.addAll(headers);
        var streamed = await request.send();
        final response = await http.Response.fromStream(streamed);
        return jsonDecode(response.body);
      },
      loadingText: 'Đang tải lên...',
    ) ?? _multipartPostWithoutLoading(endpoint, data, image, headers: headers);
  }

  static Future<Map<String, dynamic>> _multipartPostWithoutLoading(String endpoint, Map<String, dynamic> data, XFile image, {Map<String, String>? headers}) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/$endpoint');
    var request = http.MultipartRequest('POST', url);
    request.fields.addAll(data.map((k, v) => MapEntry(k, v.toString())));
    request.files.add(await http.MultipartFile.fromPath('evident', image.path));
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (headers != null) request.headers.addAll(headers);
    var streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> processAction({
    required String endpoint,
    required Map<String, dynamic> data,
    XFile? image,
    Map<String, String>? headers,
  }) async {
    if (image != null) {
      return await multipartPost(endpoint, data, image, headers: headers);
    } else {
      return await post(endpoint, data, headers: headers);
    }
  }

  static Future<Map<String, dynamic>?> getUserReport() async {
    return _loadingManager?.withLoading(
      () async {
        final token = await getToken();
        final url = Uri.parse('$baseUrl/reports/by-user');
        final response = await http.get(url, headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        });
        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          return null;
        }
      },
      loadingText: 'Đang tải dữ liệu...',
    ) ?? _getUserReportWithoutLoading();
  }

  static Future<Map<String, dynamic>?> _getUserReportWithoutLoading() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/reports/by-user');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    return _loadingManager?.withLoading(
      () async {
        final token = await getToken();
        final url = Uri.parse('$baseUrl/me');
        final response = await http.get(url, headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        });
        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          return null;
        }
      },
      loadingText: 'Đang tải thông tin...',
    ) ?? _getUserDataWithoutLoading();
  }

  static Future<Map<String, dynamic>?> _getUserDataWithoutLoading() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/me');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getMasterData() async {
    return _loadingManager?.withLoading(
      () async {
        final token = await getToken();
        final url = Uri.parse('$baseUrl/get-master-data');
        final response = await http.get(url, headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        });
        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          return null;
        }
      },
      loadingText: 'Đang tải dữ liệu...',
    ) ?? _getMasterDataWithoutLoading();
  }

  static Future<Map<String, dynamic>?> _getMasterDataWithoutLoading() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/get-master-data');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }
} 