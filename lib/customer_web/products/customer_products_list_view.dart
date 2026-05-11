import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'customer_product_viewmodel.dart';
import '../orders/customer_order_viewmodel.dart';
import '../auth/customer_auth_viewmodel.dart';
import '../../owner_web/products/product_model.dart';
import '../auth/customer_login_view.dart';
import '../orders/customer_order_view.dart';
import '../profile/customer_profile_view.dart';
import '../../res/app_resources.dart';
import '../../services/language_provider.dart';
import '../../services/theme_provider.dart';

/// صفحة عرض المنتجات للعميل (ويب) - قراءة فقط من Firebase
class CustomerProductsListView extends StatefulWidget {
  const CustomerProductsListView({super.key});

  @override
  State<CustomerProductsListView> createState() =>
      _CustomerProductsListViewState();
}

class _CustomerProductsListViewState extends State<CustomerProductsListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProductViewModel>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: Consumer<CustomerOrderViewModel>(
        builder: (context, orderVm, _) {
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomerOrderView()),
              );
            },
            backgroundColor: const Color(0xFF8B5CF6),
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            label: Text(
              '${AppStrings.get(context, 'cart')} (${orderVm.cartCount})',
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
      body: CustomScrollView(
        slivers: [
          // ─── AppBar ───
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            actions: [
              Consumer<CustomerAuthViewModel>(
                builder: (context, authVm, _) {
                  return IconButton(
                    tooltip: authVm.isLoggedIn ? AppStrings.get(context, 'my_account') : AppStrings.get(context, 'login'),
                    icon: Icon(
                      authVm.isLoggedIn ? Icons.account_circle : Icons.person_outline,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => authVm.isLoggedIn
                              ? const CustomerProfileView()
                              : const CustomerLoginView(),
                        ),
                      );
                    },
                  );
                },
              ),
              IconButton(
                onPressed: () => context.read<LanguageProvider>().toggleLanguage(),
                icon: Icon(Icons.translate, color: Theme.of(context).colorScheme.onSurface),
                tooltip: AppStrings.get(context, 'change_language'),
              ),
              IconButton(
                onPressed: () => context.read<ThemeProvider>().toggleTheme(),
                icon: Icon(
                  context.watch<ThemeProvider>().isDarkMode 
                    ? Icons.light_mode_rounded 
                    : Icons.dark_mode_rounded,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                tooltip: Theme.of(context).brightness == Brightness.dark 
                    ? 'الوضع الفاتح' 
                    : 'الوضع الليلي',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A0A2E), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      const Icon(Icons.spa_rounded,
                          color: Colors.white, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.get(context, 'app_title'),
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        AppStrings.get(context, 'discover_luxury'),
                        style: GoogleFonts.cairo(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ─── شريط البحث والفلترة ───
          SliverToBoxAdapter(
            child: Consumer<CustomerProductViewModel>(
              builder: (context, vm, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // حقل البحث
                    TextField(
                      style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface),
                      textDirection: TextDirection.rtl,
                      onChanged: vm.search,
                      decoration: InputDecoration(
                        hintText: AppStrings.get(context, 'search_hint'),
                        hintStyle:
                            GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: Color(0xFF8B5CF6)),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // أزرار الفلترة
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: vm.categories
                            .map((cat) => _CategoryChip(
                                  label: AppStrings.get(context, cat),
                                  isSelected: vm.selectedCategory == cat,
                                  onTap: () => vm.filterByCategory(cat),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── قائمة المنتجات ───
          Consumer<CustomerProductViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF8B5CF6)),
                  ),
                );
              }
              if (vm.filteredProducts.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded,
                            color: Color(0xFF8B5CF6), size: 64),
                        const SizedBox(height: 16),
                        Text(AppStrings.get(context, 'no_results'),
                            style: GoogleFonts.cairo(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 18)),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) =>
                        _ProductCard(product: vm.filteredProducts[i]),
                    childCount: vm.filteredProducts.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ─── شريحة الفئة ───
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip(
      {required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(left: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected
              ? const Color(0xFF8B5CF6)
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─── كارد المنتج للعميل ───
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withOpacity(0.12),
            Theme.of(context).colorScheme.onSurface.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border:
            Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // الصورة (أيقونة افتراضية)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withOpacity(0.3),
                    const Color(0xFF1A0A2E),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.spa_rounded,
                      color: Color(0xFF8B5CF6), size: 48),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF8B5CF6).withOpacity(0.25),
                    ),
                    child: Text(
                      AppStrings.get(context, product.category),
                      style: GoogleFonts.cairo(
                          color: Colors.white.withOpacity(0.9), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // معلومات المنتج
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.cairo(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  product.brand,
                  style: GoogleFonts.cairo(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.size,
                      style: GoogleFonts.cairo(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 11),
                    ),
                    Text(
                      '${product.price.toStringAsFixed(0)} ${AppStrings.get(context, 'currency')}',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF8B5CF6),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${AppStrings.get(context, 'remaining')}: ${product.stock}',
                      style: GoogleFonts.cairo(
                        color: product.stock > 0 ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7) : Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: product.stock > 0 ? const Color(0xFF8B5CF6) : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: product.stock <= 0 ? null : () {
                      final vm = context.read<CustomerOrderViewModel>();
                      final success = vm.addToCart(product);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                AppStrings.get(context, 'added_to_cart').replaceAll('{name}', product.name),
                                style: GoogleFonts.cairo()),
                            duration: const Duration(seconds: 1),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppStrings.parseMessage(context, vm.message ?? 'generic_error'), style: GoogleFonts.cairo()),
                            duration: const Duration(seconds: 2),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 16),
                    label: Text(
                      AppStrings.get(context, 'add_to_cart'),
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
