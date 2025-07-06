class Product {
  final int id;
  final String name;
  final String code;
  final int? parentId;

  Product({
    required this.id,
    required this.name,
    required this.code,
    this.parentId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      parentId: json['parent_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'parent_id': parentId,
    };
  }
}

class Process {
  final int id;
  final String name;
  final String code;
  final int? parentId;

  Process({
    required this.id,
    required this.name,
    required this.code,
    this.parentId,
  });

  factory Process.fromJson(Map<String, dynamic> json) {
    return Process(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      parentId: json['parent_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'parent_id': parentId,
    };
  }
}

class MasterData {
  final List<Product> products;
  final List<Process> processes;

  MasterData({
    required this.products,
    required this.processes,
  });

  factory MasterData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final productsList = data['products'] as List? ?? [];
    final processesList = data['processes'] as List? ?? [];

    return MasterData(
      products: productsList.map((product) => Product.fromJson(product)).toList(),
      processes: processesList.map((process) => Process.fromJson(process)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'products': products.map((product) => product.toJson()).toList(),
        'processes': processes.map((process) => process.toJson()).toList(),
      },
    };
  }

  List<Process> getProcessesByProductId(int productId) {
    return processes.where((process) => process.parentId == productId).toList();
  }
} 