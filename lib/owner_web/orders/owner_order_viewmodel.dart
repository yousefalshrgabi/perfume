import 'package:flutter/material.dart';
import 'order_model.dart';
import '../../services/firebase_order_service.dart';
import '../products/product_viewmodel.dart';

/// ViewModel للمالك - إدارة الطلبات (قبول / رفض)
class OwnerOrderViewModel extends ChangeNotifier {
  final FirebaseOrderService _service = FirebaseOrderService();

  bool isLoading = false;
  String? message;

  // ─── Stream مباشر للطلبات ───
  Stream<List<OrderModel>> get ordersStream => _service.getAllOrdersStream();

  // ─── قبول الطلب ───
  Future<void> acceptOrder(OrderModel order, ProductViewModel productVm) async {
    isLoading = true;
    message = null;
    notifyListeners();
    try {
      await _service.updateOrderStatus(order.id, OrderStatus.accepted);

      // ملاحظة: تم إنقاص المخزون مسبقاً عند إرسال الطلب من قبل العميل
      // فلا حاجة لإنقاصه مرة أخرى هنا

      message = 'order_accepted_msg';
    } catch (e) {
      message = 'error_msg|${e.toString()}';
    }
    isLoading = false;
    notifyListeners();
  }

  // ─── إلغاء الطلب ───
  Future<void> cancelOrder(OrderModel order, ProductViewModel productVm) async {
    isLoading = true;
    message = null;
    notifyListeners();
    try {
      await _service.updateOrderStatus(order.id, OrderStatus.cancelled);

      // إرجاع الكمية للمخزون (لأنها حُجزت عند إنشاء الطلب)
      for (var item in order.items) {
        await productVm.increaseStock(item.productId, item.quantity);
      }

      message = 'order_cancelled_msg';
    } catch (e) {
      message = 'error_msg|${e.toString()}';
    }
    isLoading = false;
    notifyListeners();
  }

  // ─── حذف الطلب ───
  Future<void> deleteOrder(String orderId) async {
    try {
      await _service.deleteOrder(orderId);
      message = 'order_deleted_msg';
      notifyListeners();
    } catch (e) {
      message = 'error_msg|${e.toString()}';
      notifyListeners();
    }
  }
}
