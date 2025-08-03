import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductsService {
  final String baseUrl =
      'https://crudcrud.com/api/021545b9c8f548829477e22dd8cb1409';
  final String resource = 'products';

  Future<List<Product>> getAllProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$resource'));
      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  Future<Product> createProduct(Product product) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$resource'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(product.toJson()),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return Product.fromJson(responseData);
      } else {
        throw Exception('Failed to create product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  Future<Product> updateProduct(String id, Product product) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$resource/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(product.toJson()),
      );

      if (response.statusCode == 200) {
        return product;
      } else {
        throw Exception('Failed to update product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$resource/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  static bool isValidQRCode(String qrData) {
    // Check if QR code matches format: <string>_<total_quantity>
    // Example: "ABC123_50" or "ORDER001_100"

    final lines = qrData.trim().split('\n').map((e) => e.trim()).toList();

    if (lines.length < 2) {
      return  false;
    }

    final orderCode = lines[0];
    final quantityLine = lines[1];

    if (orderCode.isEmpty) {
      return  false;
    }

    // Tìm số nguyên đầu tiên trong dòng 2
    final quantityMatch = RegExp(r'\d+').firstMatch(quantityLine);
    if (quantityMatch == null) {
      return false;
    }

    final quantity = int.parse(quantityMatch.group(0)!);
    if (quantity <= 0) {
      return false;
    }

    return true;
  }

  static Map<String, dynamic> parseQRCode(String qrData) {
    final lines = qrData.trim().split('\n').map((e) => e.trim()).toList();

    if (lines.length < 2) {
      throw FormatException('QR code must contain at least 2 lines.');
    }

    final orderCode = lines[0];
    final quantityLine = lines[1];

    if (orderCode.isEmpty) {
      throw FormatException('Order code cannot be empty.');
    }

    // Tìm số nguyên đầu tiên trong dòng 2
    final quantityMatch = RegExp(r'\d+').firstMatch(quantityLine);
    if (quantityMatch == null) {
      throw FormatException('Could not find quantity in line 2.');
    }

    final quantity = int.parse(quantityMatch.group(0)!);
    if (quantity <= 0) {
      throw FormatException('Quantity must be a positive number.');
    }

    return {
      'orderCode': orderCode,
      'quantity': quantity,
    };
  }
}
