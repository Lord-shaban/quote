import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_screen.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'homePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _themeMode = ThemeMode.values[prefs.getInt('theme_mode') ?? 0];
        _locale = Locale(prefs.getString('language') ?? 'en');
        _isLoading = false;
      });
    } catch (e) {
      // في حالة حدوث خطأ، استخدم القيم الافتراضية
      setState(() {
        _themeMode = ThemeMode.system;
        _locale = const Locale('en');
        _isLoading = false;
      });
    }
  }

  Future<void> changeTheme(ThemeMode themeMode) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _themeMode = themeMode;
      });
      await prefs.setInt('theme_mode', themeMode.index);
    } catch (e) {
      // معالجة الخطأ
      debugPrint('Error saving theme preference: $e');
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _locale = Locale(languageCode);
      });
      await prefs.setString('language', languageCode);
    } catch (e) {
      // معالجة الخطأ
      debugPrint('Error saving language preference: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // إظهار شاشة تحميل أثناء تحميل التفضيلات
    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                ],
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Quote',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,

      // Light Theme
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667eea),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),

      // Dark Theme
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667eea),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),

      locale: _locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ar', ''),
      ],

      home: SplashScreen(
        onThemeChanged: changeTheme,
        onLanguageChanged: changeLanguage,
        currentTheme: _themeMode,
        currentLocale: _locale,
      ),

      routes: {
        '/login': (context) => LoginPage(
          onThemeChanged: changeTheme,
          onLanguageChanged: changeLanguage,
          currentTheme: _themeMode,
          currentLocale: _locale,
        ),
        '/signup': (context) => SignupPage(
          onThemeChanged: changeTheme,
          onLanguageChanged: changeLanguage,
          currentTheme: _themeMode,
          currentLocale: _locale,
        ),
        '/home': (context) => HomePage( // إضافة مسار HomePage
          onThemeChanged: changeTheme,
          onLanguageChanged: changeLanguage,
          currentTheme: _themeMode,
          currentLocale: _locale,
        ),
      },

      // معالج الأخطاء للمسارات غير الموجودة
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => SplashScreen(
            onThemeChanged: changeTheme,
            onLanguageChanged: changeLanguage,
            currentTheme: _themeMode,
            currentLocale: _locale,
          ),
        );
      },
    );
  }
}