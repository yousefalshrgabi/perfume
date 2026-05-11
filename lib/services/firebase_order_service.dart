import 'package:cloud_firestore/cloud_firestore.dart';
import '../owner_web/orders/order_model.dart';

/// خدمة Firebase للطلبات
class FirebaseOrderService {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('orders');

  // ─── إنشاء طلب جديد ───
  Future<String> createOrder(OrderModel order) async {
    final doc = await _col.add(order.toFirestore());
    return doc.id;
  }

  // ─── جلب جميع الطلبات (للمالك) ───
  Stream<List<OrderModel>> getAllOrdersStream() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList());
  }

  // ─── جلب طلبات عميل بعينه (برقم هاتفه) ───
  Stream<List<OrderModel>> getCustomerOrdersStream(String phone) {
    return _col
        .where('customerPhone', isEqualTo: phone)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
          // فرز محلي لتجنب الحاجة لـ Firebase Index
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ─── جلب طلبات عميل بواسطة customerId (معرف حساب Firebase) ───
  Stream<List<OrderModel>> getOrdersByUserIdStream(String userId) {
    return _col
        .where('customerId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
          // فرز محلي لتجنب الحاجة لـ Firebase Index
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ─── تحديث حالة الطلب ───
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _col.doc(orderId).update({'status': status.value});
  }

  // ─── حذف طلب ───
  Future<void> deleteOrder(String orderId) async {
    await _col.doc(orderId).delete();
  }
}
