class OrderCode {
  final String orderCode;
  final int quantity;
  final String qrData;

  OrderCode({required this.orderCode, required this.quantity, required this.qrData});

  factory OrderCode.fromJson(Map<String, dynamic> json) {
    return OrderCode(
      orderCode: json['orderCode'] ?? '',
      quantity: (json['quantity'] as num).toInt(),
      qrData: json['qrData'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderCode': orderCode,
      'quantity': quantity,
      'qrData': qrData,
    };
  }
}
