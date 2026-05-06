import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../../models/order_model.dart';
import '../viewmodels/customer_auth_viewmodel.dart';
import '../viewmodels/customer_order_viewmodel.dart';
import 'auth/customer_login_view.dart';
import '../../res/app_resources.dart';
import '../../services/language_provider.dart';

class CustomerProfileView extends StatefulWidget {
  const CustomerProfileView({super.key});

  @override
  State<CustomerProfileView> createState() => _CustomerProfileViewState();
}

class _CustomerProfileViewState extends State<CustomerProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVm = context.read<CustomerAuthViewModel>();
      final orderVm = context.read<CustomerOrderViewModel>();
      if (authVm.currentUser != null) {
        orderVm.loadUserOrders(authVm.currentUser!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          AppStrings.get(context, 'profile'),
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: AppStrings.get(context, 'change_language'),
            onPressed: () {
              context.read<LanguageProvider>().toggleLanguage();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppStrings.get(context, 'logout'),
            onPressed: () {
              context.read<CustomerAuthViewModel>().logout();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Consumer2<CustomerAuthViewModel, CustomerOrderViewModel>(
        builder: (context, authVm, orderVm, _) {
          final user = authVm.currentUser;
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 80, color: Colors.white54),
                  const SizedBox(height: 20),
                  Text(
                    AppStrings.get(context, 'login_required_profile'),
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CustomerLoginView()),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                    child: Text(AppStrings.get(context, 'login'), style: GoogleFonts.cairo(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // بيانات الحساب
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFF8B5CF6),
                      child: Icon(Icons.person, size: 35, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? AppStrings.get(context, 'no_name'),
                          style: GoogleFonts.cairo(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user.email ?? '',
                          style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // عنوان قائمة الطلبات
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.get(context, 'previous_orders'),
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.history, color: Colors.white70),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, indent: 16, endIndent: 16),

              // قائمة الطلبات
              Expanded(
                child: StreamBuilder<List<OrderModel>>(
                  stream: orderVm.userOrdersStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(color: AppColors.error, fontSize: 14),
                          ),
                        ),
                      );
                    }

                    final orders = snapshot.data ?? [];
                    if (orders.isEmpty) {
                      return Center(
                        child: Text(
                          AppStrings.get(context, 'no_previous_orders'),
                          style: GoogleFonts.cairo(color: Colors.white54, fontSize: 18),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return _OrderHistoryCard(order: order);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  final OrderModel order;
  const _OrderHistoryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (order.status) {
      case OrderStatus.pending:
        statusColor = Colors.orange;
        break;
      case OrderStatus.accepted:
        statusColor = Colors.green;
        break;
      case OrderStatus.cancelled:
        statusColor = Colors.red;
        break;
    }

    final dateStr = intl.DateFormat('yyyy/MM/dd HH:mm').format(order.createdAt);

    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppStrings.get(context, 'order_id')}${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                  style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    order.status.getLabel(context),
                    style: GoogleFonts.cairo(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${AppStrings.get(context, 'date')}: $dateStr', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
            const Divider(color: Colors.white24),
            Text(
              '${AppStrings.get(context, 'items_count').replaceFirst('{count}', order.totalItems.toString())}:',
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            ...order.items.map((item) => Text(
                  '${item.quantity}x ${item.productName} (${item.price} ${AppStrings.get(context, 'currency')})',
                  style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13),
                )),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${AppStrings.get(context, 'total')}: ${order.totalAmount} ${AppStrings.get(context, 'currency')}',
                  style: GoogleFonts.cairo(color: const Color(0xFF8B5CF6), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
