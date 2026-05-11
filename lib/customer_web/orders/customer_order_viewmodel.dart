import 'package:flutter/material.dart';
import '../../owner_web/orders/order_model.dart';
import '../../owner_web/products/product_model.dart';
import '../../services/firebase_order_service.dart';
import '../../services/firebase_product_service.dart';

/// ViewModel للعميل - إدارة سلة التسوق وإرسال الطلبات
class CustomerOrderViewModel extends ChangeNotifier {
  final FirebaseOrderService _service = FirebaseOrderService();
  final FirebaseProductService _productService = FirebaseProductService();

  // ─── السلة ───
  final List<OrderItem> _cartItems = [];
  List<OrderItem> get cartItems => List.unmodifiable(_cartItems);
  int get cartCount => _cartItems.fold(0, (s, i) => s + i.quantity);
  double get cartTotal => _cartItems.fold(0, (s, i) => s + i.total);

  // ─── حالة الإرسال ───
  bool isSubmitting = false;
  String? message;

  // ─── الطلبات السابقة للعميل (برقم الهاتف) ───
  Stream<List<OrderModel>>? ordersStream;

  // ─── طلبات العميل المربوطة بحسابه ───
  Stream<List<OrderModel>>? userOrdersStream;

  // ─── إضافة منتج للسلة ───
  bool addToCart(ProductModel product, {int quantity = 1}) {
    final idx = _cartItems.indexWhere((i) => i.productId == product.id);
    int currentQty = idx >= 0 ? _cartItems[idx].quantity : 0;

    if (currentQty + quantity > product.stock) {
      message = 'qty_exceeds_stock|${product.stock}';
      notifyListeners();
      return false;
    }

    if (idx >= 0) {
      _cartItems[idx].quantity += quantity;
    } else {
      _cartItems.add(
        OrderItem(
          productId: product.id,
          productName: product.name,
          brand: product.brand,
          size: product.size,
          price: product.price,
          quantity: quantity,
          maxStock: product.stock,
        ),
      );
    }
    notifyListeners();
    return true;
  }

  // ─── إزالة من السلة ───
  void removeFromCart(String productId) {
    _cartItems.removeWhere((i) => i.productId == productId);
    notifyListeners();
  }

  // ─── تغيير الكمية ───
  void updateQuantity(String productId, int quantity) {
    final idx = _cartItems.indexWhere((i) => i.productId == productId);
    if (idx >= 0) {
      if (quantity > _cartItems[idx].maxStock) {
        message = 'max_stock_reached';
        notifyListeners();
        return;
      }
      if (quantity <= 0) {
        _cartItems.removeAt(idx);
      } else {
        _cartItems[idx].quantity = quantity;
      }
      notifyListeners();
    }
  }

  // ─── مسح السلة ───
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // ─── إرسال الطلب ───
  Future<bool> submitOrder({
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    String? notes,
    String? customerId, // معرف حساب العميل (Firebase UID)
  }) async {
    if (_cartItems.isEmpty) {
      message = 'cart_empty';
      notifyListeners();
      return false;
    }

    isSubmitting = true;
    message = null;
    notifyListeners();

    try {
      final order = OrderModel(
        id: '',
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        items: List.from(_cartItems),
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        notes: notes,
        customerId: customerId, // ربط الطلب بحساب العميل
      );

      await _service.createOrder(order);

      // إنقاص المخزون مباشرة بعد إرسال الطلب (حجز الكمية)
      for (var item in order.items) {
        await _productService.decrementStock(item.productId, item.quantity);
      }

      clearCart();
      message = 'order_submitted_success';
      isSubmitting = false;
      notifyListeners();

      // تحميل طلبات العميل
      loadCustomerOrders(customerPhone);
      if (customerId != null) {
        loadUserOrders(customerId);
      }
      return true;
    } catch (e) {
      message = 'error_msg|${e.toString()}';
      isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // ─── جلب طلبات العميل (برقم الهاتف) ───
  void loadCustomerOrders(String phone) {
    ordersStream = _service.getCustomerOrdersStream(phone);
    notifyListeners();
  }

  // ─── جلب طلبات العميل (بالحساب – userId) لاستخدامها في صفحة البروفايل
  void loadUserOrders(String userId) {
    userOrdersStream = _service.getOrdersByUserIdStream(userId);
    notifyListeners();
  }
}
