import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/customer_auth_viewmodel.dart';
import 'customer_register_view.dart';
import '../../../res/app_resources.dart';

class CustomerLoginView extends StatefulWidget {
  const CustomerLoginView({super.key});

  @override
  State<CustomerLoginView> createState() => _CustomerLoginViewState();
}

class _CustomerLoginViewState extends State<CustomerLoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    final vm = context.read<CustomerAuthViewModel>();
    final success = await vm.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    
    if (success && mounted) {
      Navigator.pop(context); // العودة للصفحة السابقة بعد الدخول
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0A2E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          AppStrings.get(context, 'customer_login_title'),
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline, size: 60, color: Color(0xFF8B5CF6)),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.get(context, 'welcome_back'),
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // رسالة الخطأ
                  Consumer<CustomerAuthViewModel>(
                    builder: (context, vm, _) {
                      if (vm.errorMessage == null) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          AppStrings.get(context, vm.errorMessage!),
                          style: GoogleFonts.cairo(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.cairo(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: AppStrings.get(context, 'email'),
                      labelStyle: GoogleFonts.cairo(color: Colors.white54),
                      prefixIcon: const Icon(Icons.email, color: Color(0xFF8B5CF6)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v!.isEmpty ? AppStrings.get(context, 'required_field') : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.cairo(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: AppStrings.get(context, 'password'),
                      labelStyle: GoogleFonts.cairo(color: Colors.white54),
                      prefixIcon: const Icon(Icons.lock, color: Color(0xFF8B5CF6)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white54,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v!.isEmpty ? AppStrings.get(context, 'required_field') : null,
                  ),
                  const SizedBox(height: 24),
                  
                  Consumer<CustomerAuthViewModel>(
                    builder: (context, vm, _) => SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: vm.isLoading ? null : _handleLogin,
                        child: vm.isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(AppStrings.get(context, 'login'), style: GoogleFonts.cairo(color: Colors.white, fontSize: 18)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const CustomerRegisterView()),
                      );
                    },
                    child: Text(
                      AppStrings.get(context, 'no_account_yet'),
                      style: GoogleFonts.cairo(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
