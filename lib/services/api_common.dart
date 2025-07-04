import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'package:image_picker/image_picker.dart';

class ApiCommon {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 60), onTimeout: () {
      throw Exception('Kết nối quá lâu, vui lòng thử lại.');
    });
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> changePassword(String token, String oldPassword, String newPassword, String confirmPassword) async {
    final url = Uri.parse('$baseUrl/users/change_password');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
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
    final url = Uri.parse('$baseUrl/$endpoint');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', ...?headers},
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> multipartPost(String endpoint, Map<String, dynamic> data, XFile image, {Map<String, String>? headers}) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    var request = http.MultipartRequest('POST', url);
    request.fields.addAll(data.map((k, v) => MapEntry(k, v.toString())));
    request.files.add(await http.MultipartFile.fromPath('evident', image.path));
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

  static Future<Map<String, dynamic>?> getUserReport({String? token}) async {
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
} 