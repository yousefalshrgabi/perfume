import 'package:cloud_firestore/cloud_firestore.dart';

/// موديل المنتج - مشترك بين الويب والجوال
class ProductModel {
  final String id;
  final String name;        // اسم العطر
  final String brand;       // الماركة
  final double price;       // السعر
  final String size;        // الحجم (مثل 100ml)
  final String category;    // الفئة: رجالي / نسائي / مختلط
  final String description; // الوصف
  final int stock;          // الكمية في المخزون
  final bool isSynced;      // ✅ هل تم رفعه على Firebase؟ (false = أوفلاين فقط)

  ProductModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.size,
    required this.category,
    required this.description,
    required this.stock,
    this.isSynced = false, // افتراضياً: غير مرفوع
  });

  // ─── تحويل للخزن في Hive (local DB) - يشمل isSynced ───
  Map<String, dynamic> toMap() => {
        'name': name,
        'brand': brand,
        'price': price,
        'size': size,
        'category': category,
        'description': description,
        'stock': stock,
        'isSynced': isSynced, // حالة المزامنة مع Firebase
      };

  factory ProductModel.fromMap(String id, Map map) => ProductModel(
        id: id,
        name: map['name'] ?? '',
        brand: map['brand'] ?? '',
        price: (map['price'] ?? 0).toDouble(),
        size: map['size'] ?? '',
        category: map['category'] ?? '',
        description: map['description'] ?? '',
        stock: (map['stock'] ?? 0).toInt(),
        isSynced: map['isSynced'] as bool? ?? false,
      );

  // ─── تحويل لـ Firebase (بدون isSynced، هذا حقل محلي فقط) ───
  Map<String, dynamic> toFirestore() => {
        'name': name,
        'brand': brand,
        'price': price,
        'size': size,
        'category': category,
        'description': description,
        'stock': stock,
      };

  factory ProductModel.fromFirestore(DocumentSnapshot doc) => ProductModel(
        id: doc.id,
        name: doc['name'] ?? '',
        brand: doc['brand'] ?? '',
        price: (doc['price'] ?? 0).toDouble(),
        size: doc['size'] ?? '',
        category: doc['category'] ?? '',
        description: doc['description'] ?? '',
        stock: (doc['stock'] ?? 0).toInt(),
        isSynced: true, // جاء من Firebase إذن هو مرفوع
      );

  // نسخة معدّلة من المنتج
  ProductModel copyWith({
    String? name,
    String? brand,
    double? price,
    String? size,
    String? category,
    String? description,
    int? stock,
    bool? isSynced,
  }) =>
      ProductModel(
        id: id,
        name: name ?? this.name,
        brand: brand ?? this.brand,
        price: price ?? this.price,
        size: size ?? this.size,
        category: category ?? this.category,
        description: description ?? this.description,
        stock: stock ?? this.stock,
        isSynced: isSynced ?? this.isSynced,
      );
}
