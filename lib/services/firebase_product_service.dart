import 'package:cloud_firestore/cloud_firestore.dart';
import '../owner_web/products/product_model.dart';

/// خدمة Firebase - تتعامل مع Firestore مباشرةً
class FirebaseProductService {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('products');

  // جلب كل المنتجات
  Future<List<ProductModel>> getAllProducts() async {
    final snapshot = await _col.get();
    return snapshot.docs
        .map((doc) => ProductModel.fromFirestore(doc))
        .toList();
  }

  // إضافة منتج
  Future<void> addProduct(ProductModel product) async {
    await _col.doc(product.id).set(product.toFirestore());
  }

  // تحديث منتج
  Future<void> updateProduct(ProductModel product) async {
    await _col.doc(product.id).update(product.toFirestore());
  }

  // حذف منتج
  Future<void> deleteProduct(String id) async {
    await _col.doc(id).delete();
  }

  // إنقاص المخزون
  Future<void> decrementStock(String id, int quantity) async {
    await _col.doc(id).update({
      'stock': FieldValue.increment(-quantity)
    });
  }

  // زيادة المخزون (إرجاع الكمية)
  Future<void> incrementStock(String id, int quantity) async {
    await _col.doc(id).update({
      'stock': FieldValue.increment(quantity)
    });
  }
}
