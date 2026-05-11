import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../../../models/product_model.dart';
import '../../../res/app_resources.dart';

/// صفحة تعديل بيانات المنتج
class EditProductView extends StatefulWidget {
  final ProductModel product;
  const EditProductView({super.key, required this.product});

  @override
  State<EditProductView> createState() => _EditProductViewState();
}

class _EditProductViewState extends State<EditProductView> {
  late TextEditingController nameCtrl;
  late TextEditingController brandCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController sizeCtrl;
  late TextEditingController descCtrl;
  late TextEditingController stockCtrl;
  late String selectedCategory;

  @override
  void initState() {
    super.initState();
    // ملء الحقول ببيانات المنتج الحالية
    nameCtrl = TextEditingController(text: widget.product.name);
    brandCtrl = TextEditingController(text: widget.product.brand);
    priceCtrl =
        TextEditingController(text: widget.product.price.toStringAsFixed(2));
    sizeCtrl = TextEditingController(text: widget.product.size);
    descCtrl = TextEditingController(text: widget.product.description);
    stockCtrl = TextEditingController(text: widget.product.stock.toString());
    // التأكد أن الفئة موجودة في القائمة، وإلا نضع الأولى كقيمة افتراضية
    final validKeys = ['men', 'women', 'unisex'];
    String currentCat = widget.product.category;
    
    // محاولة تحويل القيم القديمة (بالعربية) إلى مفاتيح إذا لزم الأمر
    if (!validKeys.contains(currentCat)) {
      if (currentCat == 'رجالي') currentCat = 'men';
      else if (currentCat == 'نسائي') currentCat = 'women';
      else if (currentCat == 'مختلط') currentCat = 'unisex';
      else currentCat = 'men'; // القيمة الافتراضية
    }
    selectedCategory = currentCat;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    brandCtrl.dispose();
    priceCtrl.dispose();
    sizeCtrl.dispose();
    descCtrl.dispose();
    stockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          AppStrings.get(context, 'edit_product_title'),
          style: GoogleFonts.cairo(
              color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // أيقونة المنتج
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.2),
              child: const Icon(Icons.spa_rounded,
                  color: Color(0xFF8B5CF6), size: 36),
            ),
            const SizedBox(height: 24),

            _field(nameCtrl, AppStrings.get(context, 'perfume_name'), Icons.spa_rounded),
            _field(brandCtrl, AppStrings.get(context, 'brand_label'), Icons.branding_watermark),
            _field(priceCtrl, AppStrings.get(context, 'price_with_currency').replaceFirst('{currency}', AppStrings.get(context, 'currency')), Icons.attach_money,
                isNumber: true),
            _field(sizeCtrl, AppStrings.get(context, 'size_hint'), Icons.straighten),
            _field(stockCtrl, AppStrings.get(context, 'stock_quantity'), Icons.inventory_2,
                isNumber: true),
            _field(descCtrl, AppStrings.get(context, 'description_label'), Icons.notes, maxLines: 3),
            const SizedBox(height: 12),

            // اختيار الفئة
            DropdownButtonFormField<String>(
              value: selectedCategory,
              dropdownColor: Theme.of(context).colorScheme.surface,
              decoration: _inputDecoration(AppStrings.get(context, 'category_label'), Icons.category),
              style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface),
              items: ['men', 'women', 'unisex']
                  .map((key) => DropdownMenuItem(
                      value: key, child: Text(AppStrings.get(context, key), style: GoogleFonts.cairo())))
                  .toList(),
              onChanged: (v) => setState(() => selectedCategory = v!),
            ),
            const SizedBox(height: 32),

            // زر حفظ التعديلات
            Consumer<ProductViewModel>(
              builder: (context, vm, _) => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: vm.isLoading ? null : () => _save(context, vm),
                  icon: vm.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded, color: Colors.white),
                  label: Text(
                    vm.isLoading ? AppStrings.get(context, 'saving') : AppStrings.get(context, 'save_changes'),
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, ProductViewModel vm) async {
    if (nameCtrl.text.isEmpty) return;

    final updated = widget.product.copyWith(
      name: nameCtrl.text.trim(),
      brand: brandCtrl.text.trim(),
      price: double.tryParse(priceCtrl.text) ?? widget.product.price,
      size: sizeCtrl.text.trim(),
      category: selectedCategory,
      description: descCtrl.text.trim(),
      stock: int.tryParse(stockCtrl.text) ?? widget.product.stock,
    );

    await vm.updateProduct(updated);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get(context, 'changes_saved_success'),
              style: GoogleFonts.cairo(color: Colors.white)),
          backgroundColor: const Color(0xFF8B5CF6),
        ),
      );
      Navigator.pop(context);
    }
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        textDirection: TextDirection.rtl,
        decoration: _inputDecoration(label, icon),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
      prefixIcon: Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
      ),
    );
  }
}
