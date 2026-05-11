import 'package:flutter/material.dart';
import '../../owner_web/products/product_model.dart';
import '../../services/firebase_product_service.dart';

/// ViewModel للعميل - يجلب المنتجات من Firebase فقط (لا يوجد local DB)
class CustomerProductViewModel extends ChangeNotifier {
  final FirebaseProductService _service = FirebaseProductService();

  List<ProductModel> _allProducts = [];
  List<ProductModel> filteredProducts = [];
  bool isLoading = false;
  String searchQuery = '';
  String selectedCategory = 'all';

  final List<String> categories = ['all', 'men', 'women', 'unisex'];

  // ─── جلب المنتجات من Firebase ───
  Future<void> loadProducts() async {
    isLoading = true;
    notifyListeners();
    try {
      _allProducts = await _service.getAllProducts();
      _applyFilters();
    } catch (e) {
      debugPrint('خطأ في جلب المنتجات: $e');
    }
    isLoading = false;
    notifyListeners();
  }

  // ─── بحث ───
  void search(String query) {
    searchQuery = query;
    _applyFilters();
  }

  // ─── فلترة حسب الفئة ───
  void filterByCategory(String category) {
    selectedCategory = category;
    _applyFilters();
  }

  void _applyFilters() {
    filteredProducts = _allProducts.where((p) {
      final matchSearch =
          searchQuery.isEmpty ||
          p.name.contains(searchQuery) ||
          p.brand.contains(searchQuery);
      final matchCategory =
          selectedCategory == 'all' ||
          p.category == selectedCategory ||
          _mapCategoryToKey(p.category) == selectedCategory;
      return matchSearch && matchCategory;
    }).toList();
    notifyListeners();
  }

  String _mapCategoryToKey(String cat) {
    switch (cat) {
      case 'الكل':
        return 'all';
      case 'رجالي':
        return 'men';
      case 'نسائي':
        return 'women';
      case 'مختلط':
        return 'unisex';
      default:
        return cat;
    }
  }
}
