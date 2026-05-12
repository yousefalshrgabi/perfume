import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'product_model.dart';
import '../../services/firebase_product_service.dart';
import '../../services/database_helper.dart';

/// ViewModel للمنتجات - يخزن في SQLite أولاً ثم يرفع لـ Firebase
class ProductViewModel extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final FirebaseProductService _service = FirebaseProductService();

  List<ProductModel> products = [];
  bool isLoading = false;
  String? message;

  // ─── الإنشاء: تحميل تلقائي عند بدء التطبيق ───
  ProductViewModel() {
    loadProducts();
  }

  // ─── توليد ID فريد ───
  String _newId() => DateTime.now().millisecondsSinceEpoch.toString();

  // ─── عدد المنتجات غير المرفوعة ───
  int get pendingCount => products.where((p) => !p.isSynced).length;

  // ─── 1. تحميل المنتجات من SQLite (محلي) ───
  Future<void> loadProducts() async {
    isLoading = true;
    notifyListeners();
    
    products = await _db.getAllProducts();
    
    isLoading = false;
    notifyListeners();
    // مزامنة من Firebase في الخلفية + رفع المنتجات المعلقة
    _syncFromFirebase();
  }

  // ─── مزامنة من Firebase في الخلفية ───
  Future<void> _syncFromFirebase() async {
    try {
      // أولاً: ارفع المنتجات غير المرفوعة (أوفلاين سابقاً)
      await syncPendingProducts();

      // ثانياً: جلب أحدث نسخة من Firebase
      final list = await _service.getAllProducts();
      await _db.clearAll();
      for (final p in list) {
        await _db.insertProduct(p); // isSynced = true لأنها من Firebase
      }
      products = list;
      notifyListeners();
    } catch (_) {
      // لا يوجد إنترنت - نبقى نعرض البيانات المحلية
    }
  }

  // ─── 2. رفع المنتجات المحفوظة أوفلاين ───
  Future<void> syncPendingProducts() async {
    final pending = products.where((p) => !p.isSynced).toList();
    if (pending.isEmpty) return;

    for (final p in pending) {
      try {
        await _service.addProduct(p);
        // نجح الرفع: حدّث الحالة في SQLite
        final synced = p.copyWith(isSynced: true);
        await _db.updateProduct(synced);
        final idx = products.indexWhere((prod) => prod.id == p.id);
        if (idx != -1) products[idx] = synced;
      } catch (_) {
        // لا زال أوفلاين، يبقى isSynced = false
      }
    }
    notifyListeners();
  }

  // ─── 3. إضافة منتج يدوياً ───
  Future<void> addProduct({
    required String name,
    required String brand,
    required double price,
    required String size,
    required String category,
    required String description,
    required int stock,
  }) async {
    isLoading = true;
    message = null;
    notifyListeners();

    // ▶ أنشئ المنتج بحالة isSynced = false
    final product = ProductModel(
      id: _newId(),
      name: name,
      brand: brand,
      price: price,
      size: size,
      category: category,
      description: description,
      stock: stock,
      isSynced: false,
    );

    // ▶ الخطوة 1: احفظ في SQLite فوراً (يعمل أوفلاين)
    await _db.insertProduct(product);
    products.add(product);
    notifyListeners();

    // ▶ الخطوة 2: حاول الرفع لـ Firebase
    try {
      await _service.addProduct(product);
      // نجح الرفع ✅ - حدّث isSynced في SQLite
      final synced = product.copyWith(isSynced: true);
      await _db.updateProduct(synced);
      final idx = products.indexWhere((p) => p.id == product.id);
      if (idx != -1) products[idx] = synced;
      message = 'product_added_firebase';
    } catch (_) {
      // فشل الرفع (أوفلاين) - المنتج محفوظ محلياً ⚠️
      message = 'product_added_local';
    }

    isLoading = false;
    notifyListeners();
  }

  // ─── 4. تحديث منتج ───
  Future<void> updateProduct(ProductModel product) async {
    isLoading = true;
    message = null;
    notifyListeners();

    // احفظ التعديل في SQLite أولاً (isSynced = false مؤقتاً)
    final updated = product.copyWith(isSynced: false);
    await _db.updateProduct(updated);
    final idx = products.indexWhere((p) => p.id == product.id);
    if (idx != -1) products[idx] = updated;
    notifyListeners();

    try {
      await _service.updateProduct(product);
      // نجح التحديث - علّم كـ synced
      final synced = product.copyWith(isSynced: true);
      await _db.updateProduct(synced);
      if (idx != -1) products[idx] = synced;
      message = 'product_updated_success';
    } catch (_) {
      message = 'product_updated_local';
    }

    isLoading = false;
    notifyListeners();
  }

  // ─── 5. حذف منتج ───
  Future<void> deleteProduct(String id) async {
    isLoading = true;
    notifyListeners();

    await _db.deleteProduct(id);
    products.removeWhere((p) => p.id == id);
    notifyListeners();

    try {
      await _service.deleteProduct(id);
      message = 'product_deleted_success';
    } catch (_) {
      message = 'product_deleted_local';
    }

    isLoading = false;
    notifyListeners();
  }

  // ─── 6. استيراد من ملف Excel ───
  Future<void> importFromExcel(List<int> bytes) async {
    isLoading = true;
    message = null;
    notifyListeners();

    try {
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.tables.keys.first]!;
      int count = 0;

      for (var i = 1; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;
        final name = _cellStr(row, 0);
        if (name.isEmpty) continue;

        final product = ProductModel(
          id: _newId(),
          name: name,
          brand: _cellStr(row, 1),
          price: double.tryParse(_cellStr(row, 2)) ?? 0,
          size: _cellStr(row, 3),
          category: _cellStr(row, 4),
          description: _cellStr(row, 5),
          stock: int.tryParse(_cellStr(row, 6)) ?? 0,
          isSynced: false,
        );

        // 1. SQLite أولاً
        await _db.insertProduct(product);
        products.add(product);

        // 2. حاول Firebase
        try {
          await _service.addProduct(product);
          final synced = product.copyWith(isSynced: true);
          await _db.updateProduct(synced);
          final idx = products.indexWhere((p) => p.id == product.id);
          if (idx != -1) products[idx] = synced;
        } catch (_) {
          // أوفلاين
        }
        count++;
      }

      final pending = products.where((p) => !p.isSynced).length;
      message = pending > 0
          ? 'excel_import_pending|$count|$pending'
          : 'excel_import_success|$count';
    } catch (e) {
      message = 'excel_read_error|${e.toString()}';
    }

    isLoading = false;
    notifyListeners();
  }

  String _cellStr(List<Data?> row, int col) {
    if (col >= row.length) return '';
    final cell = row[col];
    if (cell?.value == null) return '';
    final v = cell!.value;
    if (v is TextCellValue) return v.value.toString().trim();
    if (v is IntCellValue) return v.value.toString();
    if (v is DoubleCellValue) return v.value.toString();
    return v.toString().trim();
  }

  // ─── 7. إنقاص المخزون ───
  Future<void> decreaseStock(String id, int quantity) async {
    final idx = products.indexWhere((p) => p.id == id);
    if (idx != -1) {
      final p = products[idx];
      final newStock = (p.stock - quantity) < 0 ? 0 : p.stock - quantity;

      final updated = p.copyWith(stock: newStock, isSynced: false);
      await _db.updateProduct(updated);
      products[idx] = updated;
      notifyListeners();

      try {
        await _service.decrementStock(id, quantity);
        final synced = updated.copyWith(isSynced: true);
        await _db.updateProduct(synced);
        products[idx] = synced;
        notifyListeners();
      } catch (_) {}
    }
  }

  // ─── 8. زيادة المخزون (إرجاع الكمية) ───
  Future<void> increaseStock(String id, int quantity) async {
    final idx = products.indexWhere((p) => p.id == id);
    if (idx != -1) {
      final p = products[idx];
      final newStock = p.stock + quantity;

      final updated = p.copyWith(stock: newStock, isSynced: false);
      await _db.updateProduct(updated);
      products[idx] = updated;
      notifyListeners();

      try {
        await _service.incrementStock(id, quantity);
        final synced = updated.copyWith(isSynced: true);
        await _db.updateProduct(synced);
        products[idx] = synced;
        notifyListeners();
      } catch (_) {}
    }
  }
}
