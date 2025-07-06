class Order {
  final int id;
  final String code;
  final int? totalQuantity;
  final String? createdAt;
  final String? notes;
  final int status;
  final String? startTime;
  final String? completedTime;
  final String? updatedAt;

  Order({
    required this.id,
    required this.code,
    this.totalQuantity,
    this.createdAt,
    this.notes,
    required this.status,
    this.startTime,
    this.completedTime,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      totalQuantity: json['total_quantity'],
      createdAt: json['created_at'],
      notes: json['notes'],
      status: json['status'] ?? 0,
      startTime: json['start_time'],
      completedTime: json['completed_time'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'total_quantity': totalQuantity,
      'created_at': createdAt,
      'notes': notes,
      'status': status,
      'start_time': startTime,
      'completed_time': completedTime,
      'updated_at': updatedAt,
    };
  }
}

class WorkingProcess {
  final int id;
  final int orderId;
  final String startTime;
  final String? completedTime;
  final int status;
  final String? note;
  final String? comment;
  final int quantity;
  final int userId;
  final int processId;
  final String? totalPendingTime;
  final String? fileId;
  final String createdAt;
  final String updatedAt;
  final Order order;

  WorkingProcess({
    required this.id,
    required this.orderId,
    required this.startTime,
    this.completedTime,
    required this.status,
    this.note,
    this.comment,
    required this.quantity,
    required this.userId,
    required this.processId,
    this.totalPendingTime,
    this.fileId,
    required this.createdAt,
    required this.updatedAt,
    required this.order,
  });

  factory WorkingProcess.fromJson(Map<String, dynamic> json) {
    return WorkingProcess(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      startTime: json['start_time'] ?? '',
      completedTime: json['completed_time'],
      status: json['status'] ?? 0,
      note: json['note'],
      comment: json['comment'],
      quantity: json['quantity'] ?? 0,
      userId: json['user_id'] ?? 0,
      processId: json['process_id'] ?? 0,
      totalPendingTime: json['total_pending_time'],
      fileId: json['file_id'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      order: Order.fromJson(json['order'] ?? {}),
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