import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth/auth_viewmodel.dart';
import '../products/product_viewmodel.dart';
import '../products/products_view.dart';
import '../orders/owner_order_view.dart';
import '../../res/app_resources.dart';
import '../../services/language_provider.dart';
import '../../services/theme_provider.dart';

/// لوحة التحكم الرئيسية لصاحب العمل (جوال)
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBgGradient
              : AppColors.lightBgGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── الهيدر ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get(context, 'hello'),
                          style: GoogleFonts.cairo(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          AppStrings.get(context, 'owner'),
                          style: GoogleFonts.cairo(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () =>
                              context.read<ThemeProvider>().toggleTheme(),
                          icon: Icon(
                            context.watch<ThemeProvider>().isDarkMode
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              context.read<LanguageProvider>().toggleLanguage(),
                          icon: Icon(
                            Icons.translate_rounded,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          tooltip: AppStrings.get(context, 'change_language'),
                        ),
                        IconButton(
                          onPressed: () async {
                            await context.read<AuthViewModel>().logout();
                            if (context.mounted) {
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          },
                          icon: Icon(
                            Icons.logout_rounded,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          tooltip: AppStrings.get(context, 'logout'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // شعار التطبيق
                Row(
                  children: [
                    Icon(Icons.spa_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      AppStrings.get(context, 'app_title'),
                      style: GoogleFonts.cairo(
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ─── عنوان القسم ───
                Text(
                  AppStrings.get(context, 'quick_actions'),
                  style: GoogleFonts.cairo(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // ─── كروت الإجراءات ───
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      // كارد إدارة المنتجات
                      _ActionCard(
                        icon: Icons.inventory_2_rounded,
                        title: AppStrings.get(context, 'manage_products'),
                        subtitle: AppStrings.get(context, 'add_edit_delete'),
                        color: AppColors.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProductsView(),
                          ),
                        ),
                      ),
                      // كارد عدد المنتجات الكلي
                      Consumer<ProductViewModel>(
                        builder: (context, vm, _) => _InfoCard(
                          icon: Icons.spa_rounded,
                          title: '${vm.products.length}',
                          subtitle: AppStrings.get(
                            context,
                            'registered_products',
                          ),
                          color: const Color(0xFF06B6D4),
                        ),
                      ),
                      // كارد المنتجات المرفوعة على Firebase
                      Consumer<ProductViewModel>(
                        builder: (context, vm, _) => _InfoCard(
                          icon: Icons.cloud_done_rounded,
                          title:
                              '${vm.products.where((p) => p.isSynced).length}',
                          subtitle: AppStrings.get(
                            context,
                            'uploaded_firebase',
                          ),
                          color: AppColors.secondary,
                        ),
                      ),
                      // كارد المنتجات غير المرفوعة (أوفلاين)
                      Consumer<ProductViewModel>(
                        builder: (context, vm, _) => _InfoCard(
                          icon: vm.pendingCount > 0
                              ? Icons.cloud_off_rounded
                              : Icons.storage_rounded,
                          title: vm.pendingCount > 0
                              ? '${vm.pendingCount}'
                              : 'Hive ✓',
                          subtitle: vm.pendingCount > 0
                              ? AppStrings.get(context, 'pending_sync')
                              : AppStrings.get(context, 'synced_local'),
                          color: vm.pendingCount > 0
                              ? Colors.orange
                              : AppColors.accent,
                        ),
                      ),
                      // كارد الطلبات
                      _ActionCard(
                        icon: Icons.receipt_long_rounded,
                        title: AppStrings.get(context, 'orders'),
                        subtitle: AppStrings.get(context, 'manage_orders'),
                        color: Colors.blueAccent,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OwnerOrderView(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── كارد إجراء قابل للضغط ───
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        //width: title == 'الطلبات' ? double.infinity : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.cairo(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: GoogleFonts.cairo(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── كارد معلومات (غير قابل للضغط) ───
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.cairo(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: GoogleFonts.cairo(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
