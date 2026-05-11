import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../viewmodels/customer_order_viewmodel.dart';
import '../viewmodels/customer_auth_viewmodel.dart';
import 'auth/customer_login_view.dart';
import '../../../res/app_resources.dart';

class CustomerOrderView extends StatefulWidget {
  const CustomerOrderView({super.key});

  @override
  State<CustomerOrderView> createState() => _CustomerOrderViewState();
}

class _CustomerOrderViewState extends State<CustomerOrderView> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // إذا كان العميل مسجل دخوله، قم بملء البيانات تلقائياً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          _nameController.text = user.displayName!;
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitOrder(CustomerOrderViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    final authVm = context.read<CustomerAuthViewModel>();
    final success = await vm.submitOrder(
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      customerAddress: _addressController.text.trim(),
      notes: _notesController.text.trim(),
      customerId: authVm.currentUser?.uid, // ربط بحساب العميل إذا كان مسجل دخوله
    );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.parseMessage(context, vm.message ?? 'order_submitted'),
              style: GoogleFonts.cairo()),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // العودة للصفحة السابقة
    } else if (mounted && !success && vm.message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.parseMessage(context, vm.message!), style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          AppStrings.get(context, 'cart_and_order'),
          style: GoogleFonts.cairo(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Consumer2<CustomerAuthViewModel, CustomerOrderViewModel>(
        builder: (context, authVm, vm, _) {
          if (authVm.currentUser == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_person_outlined, size: 80, color: Color(0xFF8B5CF6)),
                    const SizedBox(height: 24),
                    Text(
                      AppStrings.get(context, 'login_required_order'),
                      style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CustomerLoginView()),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                        child: Text(AppStrings.get(context, 'login_create_account'), style: GoogleFonts.cairo(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (vm.cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.white54),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.get(context, 'cart_empty'),
                    style: GoogleFonts.cairo(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 20),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── عناصر السلة ───
              Text(
                '${AppStrings.get(context, 'products')} (${vm.cartCount})',
                style: GoogleFonts.cairo(
                    color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...vm.cartItems.map((item) => Card(
                    color: Colors.white.withOpacity(0.05),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(item.productName,
                          style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface)),
                      subtitle: Text('${item.price} ${AppStrings.get(context, 'currency')} x ${item.quantity}',
                          style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.redAccent),
                            onPressed: () => vm.updateQuantity(
                                item.productId, item.quantity - 1),
                          ),
                          Text('${item.quantity}',
                              style: GoogleFonts.cairo(
                                  color: Theme.of(context).colorScheme.onSurface, fontSize: 16)),
                          IconButton(
                            icon: Icon(Icons.add_circle_outline,
                                color: item.quantity >= item.maxStock ? Colors.grey : Colors.greenAccent),
                            onPressed: item.quantity >= item.maxStock ? null : () => vm.updateQuantity(
                                item.productId, item.quantity + 1),
                          ),
                        ],
                      ),
                    ),
                  )),
              const Divider(color: Colors.white24, height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppStrings.get(context, 'total')}: ${vm.cartTotal.toStringAsFixed(2)} ${AppStrings.get(context, 'currency')}',
                    style: GoogleFonts.cairo(
                        color: const Color(0xFF8B5CF6),
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    AppStrings.get(context, 'grand_total'),
                    style: GoogleFonts.cairo(
                        color: Theme.of(context).colorScheme.onSurface, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // ─── نموذج معلومات العميل ───
              Text(
                AppStrings.get(context, 'delivery_info'),
                style: GoogleFonts.cairo(
                    color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: AppStrings.get(context, 'full_name'),
                      icon: Icons.person,
                      validator: (v) => v!.isEmpty ? AppStrings.get(context, 'required_field') : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _phoneController,
                      label: AppStrings.get(context, 'phone_number'),
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? AppStrings.get(context, 'required_field') : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _addressController,
                      label: AppStrings.get(context, 'delivery_address'),
                      icon: Icons.location_on,
                      validator: (v) => v!.isEmpty ? AppStrings.get(context, 'required_field') : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _notesController,
                      label: AppStrings.get(context, 'additional_notes'),
                      icon: Icons.note,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // ─── زر الإرسال ───
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: vm.isSubmitting ? null : () => _submitOrder(vm),
                  child: vm.isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          AppStrings.get(context, 'confirm_order'),
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface),
      textDirection: TextDirection.rtl,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: const Color(0xFF8B5CF6)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorStyle: GoogleFonts.cairo(color: Colors.redAccent),
      ),
    );
  }
}
