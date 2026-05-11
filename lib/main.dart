import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// ─── صاحب العمل (الجوال) ───
import 'owner_web/auth/auth_viewmodel.dart';
import 'owner_web/products/product_viewmodel.dart';
import 'owner_web/orders/owner_order_viewmodel.dart';
import 'owner_web/auth/login_view.dart';
import 'owner_web/dashboard/dashboard_view.dart';
import 'owner_web/splash/splash_view.dart';

// ─── العميل (الويب) ───
import 'customer_web/products/customer_product_viewmodel.dart';
import 'customer_web/orders/customer_order_viewmodel.dart';
import 'customer_web/auth/customer_auth_viewmodel.dart';
import 'customer_web/products/customer_products_list_view.dart';
import 'services/language_provider.dart';
import 'services/theme_provider.dart';
import 'res/app_resources.dart';
import 'res/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── 1. تهيئة Firebase (للجميع) ───
  String? initError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase error: $e');
    initError = e.toString();
  }

  // ─── 2. تهيئة Hive (للجوال فقط - صاحب العمل) ───
  if (!kIsWeb) {
    await Hive.initFlutter();
    await Hive.openBox('products'); // فتح صندوق المنتجات المحلي
  }

  // ─── 3. تشغيل التطبيق المناسب ───
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MyApp(initError: initError),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? initError;
  const MyApp({super.key, this.initError});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    // عرض خطأ التهيئة إذا وجد
    if (initError != null) {
      return MaterialApp(
        locale: languageProvider.currentLocale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ar'),
          Locale('en'),
        ],
        home: Scaffold(
          body: Center(
            child: Text(
              '${AppStrings.get(context, 'init_error')}\n$initError',
              textDirection: languageProvider.currentLocale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              style: const TextStyle(color: Colors.red, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // ─── إذا كان ويب → واجهة العميل ───
    if (kIsWeb) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CustomerAuthViewModel()),
          ChangeNotifierProvider(create: (_) => CustomerProductViewModel()),
          ChangeNotifierProvider(create: (_) => CustomerOrderViewModel()),
        ],
        child: Consumer<LanguageProvider>(
          builder: (context, lang, _) => MaterialApp(
            title: AppStrings.get(context, 'app_title', langCode: lang.currentLocale.languageCode),
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: lang.currentLocale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ar'),
              Locale('en'),
            ],
            home: const CustomerProductsListView(),
          ),
        ),
      );
    }

    // ─── إذا كان جوال → واجهة صاحب العمل ───
    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ProductViewModel()),
        ChangeNotifierProvider(create: (_) => OwnerOrderViewModel()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, lang, _) => MaterialApp(
          title: AppStrings.get(context, 'app_title', langCode: lang.currentLocale.languageCode),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          locale: lang.currentLocale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          initialRoute: '/splash',
          routes: {
            '/splash': (_) => SplashView(nextRoute: isLoggedIn ? '/dashboard' : '/login'),
            '/login': (_) => const LoginView(),
            '/dashboard': (_) => const DashboardView(),
          },
        ),
      ),
    );
  }

}
