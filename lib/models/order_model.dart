import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../res/app_resources.dart';

/// عنصر داخل الطلب
class OrderItem {
  final String productId;
  final String productName;
  final String brand;
  final String size;
  final double price;
  int quantity;
  final int maxStock;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.brand,
    required this.size,
    required this.price,
    required this.quantity,
    required this.maxStock,
  });

  double get total => price * quantity;

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'brand': brand,
        'size': size,
        'price': price,
        'quantity': quantity,
        'maxStock': maxStock,
      };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        productId: map['productId'] ?? '',
        productName: map['productName'] ?? '',
        brand: map['brand'] ?? '',
        size: map['size'] ?? '',
        price: (map['price'] ?? 0).toDouble(),
        quantity: (map['quantity'] ?? 1).toInt(),
        maxStock: (map['maxStock'] ?? 0).toInt(),
      );
}

/// حالة الطلب
enum OrderStatus { pending, accepted, cancelled }

extension OrderStatusExt on OrderStatus {
  String getLabel(BuildContext context) {
    switch (this) {
      case OrderStatus.pending:
        return AppStrings.get(context, 'status_pending');
      case OrderStatus.accepted:
        return AppStrings.get(context, 'status_accepted');
      case OrderStatus.cancelled:
        return AppStrings.get(context, 'status_cancelled');
    }
  }

  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.accepted:
        return 'accepted';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }
}

OrderStatus orderStatusFromString(String s) {
  switch (s) {
    case 'accepted':
      return OrderStatus.accepted;
    case 'cancelled':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.pending;
  }
}

/// موديل الطلب الكامل
class OrderModel {
  final String id;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime createdAt;
  final String? notes;
  final String? customerId; // ربط الطلب بحساب العميل (اختياري)

  OrderModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.items,
    required this.status,
    required this.createdAt,
    this.notes,
    this.customerId,
  });

  double get totalAmount => items.fold(0, (sum, item) => sum + item.total);
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toFirestore() => {
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerAddress': customerAddress,
        'items': items.map((i) => i.toMap()).toList(),
        'status': status.value,
        'createdAt': Timestamp.fromDate(createdAt),
        'notes': notes ?? '',
        if (customerId != null) 'customerId': customerId,
      };

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerAddress: data['customerAddress'] ?? '',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((i) => OrderItem.fromMap(Map<String, dynamic>.from(i as Map)))
          .toList(),
      status: orderStatusFromString(data['status'] ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'],
      customerId: data['customerId'],
    );
  }

  OrderModel copyWith({OrderStatus? status}) => OrderModel(
        id: id,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        items: items,
        status: status ?? this.status,
        createdAt: createdAt,
        notes: notes,
        customerId: customerId,
      );
}
