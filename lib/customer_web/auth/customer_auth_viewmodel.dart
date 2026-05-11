import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerAuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;
  String? errorMessage;

  // التحقق من حالة تسجيل الدخول
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  // تسجيل الدخول
  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      isLoading = false;
      errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }

  // إنشاء حساب جديد
  Future<bool> register(String email, String password, String name) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // تحديث اسم المستخدم
      await cred.user?.updateDisplayName(name);

      isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      isLoading = false;
      errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }

  // تسجيل الخروج
  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }

  // ترجمة رسائل الخطأ
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'user_not_found';
      case 'wrong-password':
        return 'wrong_password';
      case 'invalid-email':
        return 'invalid_email';
      case 'email-already-in-use':
        return 'email_already_in_use';
      case 'weak-password':
        return 'weak_password';
      case 'invalid-credential':
        return 'invalid_credential';
      default:
        return 'generic_error';
    }
  }
}
