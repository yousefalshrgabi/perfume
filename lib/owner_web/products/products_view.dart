import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'product_viewmodel.dart';
import 'product_model.dart';
import 'edit_product_view.dart';
import '../../res/app_resources.dart';

class ProductsView extends StatefulWidget {
  const ProductsView({super.key});

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  @override
  void initState() {
    super.initState();
    // ملاحظة: loadProducts() يُستدعى تلقائياً من ProductViewModel()
    // لكن نعيد المزامنة عند فتح الصفحة لضمان أحدث البيانات
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductViewModel>().syncPendingProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          AppStrings.get(context, 'manage_products'),
          style: GoogleFonts.cairo(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        actions: [
          // مؤشر المنتجات غير المرفوعة
          Consumer<ProductViewModel>(
            builder: (_, vm, __) => vm.pendingCount > 0
                ? Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Tooltip(
                      message: AppStrings.get(
                        context,
                        'pending_sync_count',
                      ).replaceFirst('{count}', vm.pendingCount.toString()),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.cloud_off_rounded,
                              color: Colors.orange,
                            ),
                            onPressed: () => vm.syncPendingProducts(),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${vm.pendingCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          // زر رفع Excel
          IconButton(
            tooltip: AppStrings.get(context, 'import_excel'),
            icon: const Icon(
              Icons.upload_file_rounded,
              color: Color(0xFF8B5CF6),
            ),
            onPressed: () => _importExcel(context),
          ),
        ],
      ),
      body: Consumer<ProductViewModel>(
        builder: (context, vm, _) {
          // عرض رسالة النجاح / الخطأ
          if (vm.message != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppStrings.parseMessage(context, vm.message!),
                    style: GoogleFonts.cairo(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  backgroundColor:
                      vm.message!.contains('error') ||
                          vm.message!.contains('error_msg')
                      ? Colors.red.shade700
                      : const Color(0xFF8B5CF6),
                ),
              );
              vm.message = null;
            });
          }

          if (vm.isLoading && vm.products.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
            );
          }

          if (vm.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.spa_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.get(context, 'no_products_yet'),
                    style: GoogleFonts.cairo(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.get(context, 'add_product_hint'),
                    style: GoogleFonts.cairo(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vm.products.length,
            itemBuilder: (context, index) {
              final product = vm.products[index];
              return _ProductCard(product: product);
            },
          );
        },
      ),
      // زر إضافة منتج يدوي
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        backgroundColor: const Color(0xFF8B5CF6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          AppStrings.get(context, 'add_product'),
          style: GoogleFonts.cairo(color: Colors.white),
        ),
      ),
    );
  }

  // ─── استيراد من Excel ───
  Future<void> _importExcel(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      if (context.mounted) {
        await context.read<ProductViewModel>().importFromExcel(
          result.files.single.bytes!,
        );
      }
    }
  }

  // ─── نموذج إضافة منتج يدوياً ───
  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final sizeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    String selectedCategory = 'men';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            AppStrings.get(context, 'add_new_product'),
            style: GoogleFonts.cairo(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(
                  nameCtrl,
                  AppStrings.get(context, 'perfume_name'),
                  Icons.spa_rounded,
                ),
                _field(
                  brandCtrl,
                  AppStrings.get(context, 'brand_label'),
                  Icons.branding_watermark,
                ),
                _field(
                  priceCtrl,
                  AppStrings.get(context, 'price_with_currency').replaceFirst(
                    '{currency}',
                    AppStrings.get(context, 'currency'),
                  ),
                  Icons.attach_money,
                  isNumber: true,
                ),
                _field(
                  sizeCtrl,
                  AppStrings.get(context, 'size_hint'),
                  Icons.straighten,
                ),
                _field(
                  stockCtrl,
                  AppStrings.get(context, 'stock_quantity'),
                  Icons.inventory_2,
                  isNumber: true,
                ),
                _field(
                  descCtrl,
                  AppStrings.get(context, 'description_label'),
                  Icons.notes,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                // اختيار الفئة
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  decoration: _inputDecoration(
                    AppStrings.get(context, 'category_label'),
                    Icons.category,
                  ),
                  style: GoogleFonts.cairo(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  items: ['men', 'women', 'unisex']
                      .map(
                        (key) => DropdownMenuItem(
                          value: key,
                          child: Text(
                            AppStrings.get(context, key),
                            style: GoogleFonts.cairo(),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedCategory = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppStrings.get(context, 'cancel'),
                style: GoogleFonts.cairo(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
              ),
              onPressed: () async {
                if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                Navigator.pop(ctx);
                await context.read<ProductViewModel>().addProduct(
                  name: nameCtrl.text.trim(),
                  brand: brandCtrl.text.trim(),
                  price: double.tryParse(priceCtrl.text) ?? 0,
                  size: sizeCtrl.text.trim(),
                  category: selectedCategory,
                  description: descCtrl.text.trim(),
                  stock: int.tryParse(stockCtrl.text) ?? 0,
                );
              },
              child: Text(
                AppStrings.get(context, 'add_product'),
                style: GoogleFonts.cairo(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // مساعد: حقل نص
  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        style: GoogleFonts.cairo(
          color: Theme.of(context).colorScheme.onSurface,
        ),
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
      labelStyle: GoogleFonts.cairo(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
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

// ─── كارد المنتج ───
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withOpacity(0.15),
            Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
          ],
        ),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.2),
              child: Text(
                product.name.isNotEmpty ? product.name[0] : '؟',
                style: GoogleFonts.cairo(
                  color: const Color(0xFF8B5CF6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // أيقونة حالة المزامنة
            Positioned(
              bottom: -2,
              right: -2,
              child: Tooltip(
                message: product.isSynced
                    ? AppStrings.get(context, 'uploaded_firebase')
                    : AppStrings.get(context, 'pending_sync'),
                child: CircleAvatar(
                  radius: 7,
                  backgroundColor: product.isSynced
                      ? const Color(0xFF10B981) // أخضر = مرفوع
                      : Colors.orange, // برتقالي = أوفلاين
                  child: Icon(
                    product.isSynced ? Icons.cloud_done : Icons.cloud_off,
                    size: 9,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          product.name,
          style: GoogleFonts.cairo(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textDirection: TextDirection.rtl,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${product.brand} • ${product.category}',
              style: GoogleFonts.cairo(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${product.price.toStringAsFixed(0)} ${AppStrings.get(context, 'currency')}',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF8B5CF6),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${AppStrings.get(context, 'stock_label')}: ${product.stock}',
                  style: GoogleFonts.cairo(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // زر تعديل
            IconButton(
              icon: const Icon(
                Icons.edit_rounded,
                color: Color(0xFF8B5CF6),
                size: 20,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProductView(product: product),
                ),
              ),
              tooltip: AppStrings.get(context, 'edit_label'),
            ),
            // زر حذف
            IconButton(
              icon: Icon(
                Icons.delete_rounded,
                color: Colors.red.shade400,
                size: 20,
              ),
              onPressed: () => _confirmDelete(context),
              tooltip: AppStrings.get(context, 'delete_label'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          AppStrings.get(context, 'delete_product'),
          style: GoogleFonts.cairo(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          AppStrings.get(
            context,
            'confirm_delete_msg',
          ).replaceFirst('{name}', product.name),
          style: GoogleFonts.cairo(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppStrings.get(context, 'cancel'),
              style: GoogleFonts.cairo(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () {
              Navigator.pop(context);
              context.read<ProductViewModel>().deleteProduct(product.id);
            },
            child: Text(
              AppStrings.get(context, 'delete_label'),
              style: GoogleFonts.cairo(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
