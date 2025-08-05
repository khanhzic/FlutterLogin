class DeliveryItems {
  final int id;
  final int orderId;
  final String? startTime;
  final String? completedTime;
  final int status;
  final String? note;
  final String? comment;
  final int quantity;
  final int userId;
  final int processId;
  final String? totalPendingTime;
  final int? fileId;
  final String? createdAt;
  final String? updatedAt;
  final Order order;

  DeliveryItems({
    required this.id,
    required this.orderId,
    this.startTime,
    this.completedTime,
    required this.status,
    this.note,
    this.comment,
    required this.quantity,
    required this.userId,
    required this.processId,
    this.totalPendingTime,
    this.fileId,
    this.createdAt,
    this.updatedAt,
    required this.order,
  });

  factory DeliveryItems.fromJson(Map<String, dynamic> json) {
    return DeliveryItems(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      startTime: json['start_time'] as String?,
      completedTime: json['completed_time'] as String?,
      status: json['status'] as int,
      note: json['note'] as String?,
      comment: json['comment'] as String?,
      quantity: (json['quantity'] as num).toInt(),
      userId: json['user_id'] as int,
      processId: json['process_id'] as int,
      totalPendingTime: json['total_pending_time'] as String?,
      fileId: json['file_id'] as int?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      order: Order.fromJson(json['order'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'start_time': startTime,
      'completed_time': completedTime,
      'status': status,
      'note': note,
      'comment': comment,
      'quantity': quantity,
      'user_id': userId,
      'process_id': processId,
      'total_pending_time': totalPendingTime,
      'file_id': fileId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'order': order.toJson(),
    };
  }
}

class Order {
  final int id;
  final String code;
  final int totalQuantity;
  final String notes;

  Order({
    required this.id,
    required this.code,
    required this.totalQuantity,
    required this.notes,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      code: json['code'] ?? '',
      totalQuantity: (json['total_quantity'] as num).toInt(),
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'total_quantity': totalQuantity,
      'notes': notes,
    };
  }
}
