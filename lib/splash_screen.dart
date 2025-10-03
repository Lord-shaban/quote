import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final Function(String) onLanguageChanged;
  final ThemeMode currentTheme;
  final Locale currentLocale;

  const SplashScreen({
    Key? key,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.currentTheme,
    required this.currentLocale,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();

    // الانتقال بعد 3 ثواني
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // شعار التطبيق
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.format_quote,
                  size: 40,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              // اسم التطبيق
              Text(
                'Quote',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}