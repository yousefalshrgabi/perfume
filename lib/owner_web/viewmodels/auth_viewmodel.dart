import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;
  String? errorMessage;
  bool rememberMe = false;

  static const String _keyRememberMe = 'remember_me';
  static const String _keyEmail = 'saved_email';

  // تحميل بيانات "تذكرني" المحفوظة
  Future<Map<String, dynamic>> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_keyRememberMe) ?? false;
    final email = prefs.getString(_keyEmail) ?? '';
    rememberMe = remember;
    notifyListeners();
    return {'rememberMe': remember, 'email': email};
  }

  // تغيير حالة تذكرني
  void toggleRememberMe(bool value) {
    rememberMe = value;
    notifyListeners();
  }

  // تسجيل الدخول
  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      final prefs = await SharedPreferences.getInstance();
      if (rememberMe) {
        await prefs.setBool(_keyRememberMe, true);
        await prefs.setString(_keyEmail, email);
      } else {
        await prefs.remove(_keyRememberMe);
        await prefs.remove(_keyEmail);
      }

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

  // تسجيل الدخول باستخدام Google
  Future<bool> signInWithGoogle() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // تم الإلغاء من قبل المستخدم
        isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      if (e is FirebaseAuthException) {
        errorMessage = 'error_msg|${_getErrorMessage(e.code)}';
      } else {
        errorMessage = 'error_msg|${e.toString()}';
      }
      notifyListeners();
      return false;
    }
  }

  // تسجيل الخروج
  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    final savedRemember = prefs.getBool(_keyRememberMe) ?? false;
    if (!savedRemember) {
      await prefs.remove(_keyEmail);
    }
  }

  // ترجمة رسائل الخطأ (إرجاع المفاتيح)
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'user_not_found';
      case 'wrong-password':
        return 'wrong_password';
      case 'invalid-email':
        return 'invalid_email';
      case 'invalid-credential':
        return 'invalid_credential';
      case 'user-disabled':
      case 'too-many-requests':
      default:
        return 'generic_error';
    }
  }

  // التحقق إذا كان المستخدم مسجل دخوله مسبقاً
  User? get currentUser => _auth.currentUser;
}
