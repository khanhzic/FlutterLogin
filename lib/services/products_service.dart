import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductsService {
  // The correct API endpoint from crudcrud.com
  final String baseUrl = 'https://crudcrud.com/api/252769ebfce44446afb19adfebed5456';
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

  Future<Product> getProduct(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/$resource/$id'));
    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load product');
    }
  }

  Future<Product> createProduct(Product product) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$resource'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': product.name,
          'price': product.price,
          'description': product.description,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return Product(
          id: responseData['_id'] ?? '',
          name: responseData['name'],
          price: responseData['price'].toDouble(),
          description: responseData['description'],
        );
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
        body: json.encode({
          'name': product.name,
          'price': product.price,
          'description': product.description,
        }),
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
} 