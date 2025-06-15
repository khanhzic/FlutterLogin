import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/products_service.dart';

class ProductsPage extends StatefulWidget {
  ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => ProductsPageState();
}

class ProductsPageState extends State<ProductsPage> {
  final ProductsService _productsService = ProductsService();
  List<Product> _products = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _productsService.getAllProducts();
      setState(() => _products = products);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> showAddEditDialog([Product? product]) async {
    final bool isEditing = product != null;
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: product?.name);
    final _priceController = TextEditingController(
      text: product?.price.toString(),
    );
    final _descriptionController = TextEditingController(
      text: product?.description,
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  final newProduct = Product(
                    id: product?.id ?? '',
                    name: _nameController.text,
                    price: double.parse(_priceController.text),
                    description: _descriptionController.text,
                  );

                  if (isEditing) {
                    await _productsService.updateProduct(product!.id, newProduct);
                  } else {
                    await _productsService.createProduct(newProduct);
                  }
                  
                  if (mounted) {
                    Navigator.pop(context);
                    loadProducts();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving product: $e')),
                  );
                }
              }
            },
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(String id) async {
    try {
      await _productsService.deleteProduct(id);
      loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inventory,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No products available',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => showAddEditDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Product'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _products.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Text(
                          '${product.description}\nPrice: \$${product.price.toStringAsFixed(2)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => showAddEditDialog(product),
                              color: Colors.blue,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteProduct(product.id),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 