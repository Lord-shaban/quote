import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class SignupPage extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final Function(String) onLanguageChanged;
  final ThemeMode currentTheme;
  final Locale currentLocale;

  const SignupPage({
    Key? key,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.currentTheme,
    required this.currentLocale,
  }) : super(key: key);

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const Color primaryColor = Color(0xFF00695C);
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF16181C);
  static const Color lightGray = Color(0xFFF7F9FA);

  Map<String, Map<String, String>> _texts = {
    'en': {
      'createAccount': 'Create Account',
      'subtitle': 'Join us today',
      'name': 'Full Name',
      'email': 'Email',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'signup': 'Sign up',
      'alreadyHaveAccount': 'Already have an account?',
      'signIn': 'Sign in',
      'nameRequired': 'Name is required',
      'emailRequired': 'Email is required',
      'emailInvalid': 'Enter a valid email',
      'passwordRequired': 'Password is required',
      'passwordShort': 'Password must be at least 6 characters',
      'confirmPasswordRequired': 'Please confirm your password',
      'passwordsDontMatch': 'Passwords don\'t match',
      'signupError': 'Signup failed. Please try again.',
      'signupSuccess': 'Account created successfully!',
      'settings': 'Settings',
      'continueWith': 'Create your account',
      'or': 'or',
      'weakPassword': 'The password provided is too weak.',
      'emailInUse': 'The account already exists for that email.',
      'invalidEmail': 'The email address is not valid.',
    },
    'ar': {
      'createAccount': 'إنشاء حساب',
      'subtitle': 'انضم إلينا اليوم',
      'name': 'الاسم الكامل',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'confirmPassword': 'تأكيد كلمة المرور',
      'signup': 'إنشاء حساب',
      'alreadyHaveAccount': 'لديك حساب بالفعل؟',
      'signIn': 'تسجيل الدخول',
      'nameRequired': 'الاسم مطلوب',
      'emailRequired': 'البريد الإلكتروني مطلوب',
      'emailInvalid': 'أدخل بريد إلكتروني صحيح',
      'passwordRequired': 'كلمة المرور مطلوبة',
      'passwordShort': 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
      'confirmPasswordRequired': 'يرجى تأكيد كلمة المرور',
      'passwordsDontMatch': 'كلمات المرور غير متطابقة',
      'signupError': 'فشل إنشاء الحساب. حاول مرة أخرى.',
      'signupSuccess': 'تم إنشاء الحساب بنجاح!',
      'settings': 'الإعدادات',
      'continueWith': 'أنشئ حسابك',
      'or': 'أو',
      'weakPassword': 'كلمة المرور المدخلة ضعيفة جداً.',
      'emailInUse': 'يوجد حساب بالفعل لهذا البريد الإلكتروني.',
      'invalidEmail': 'البريد الإلكتروني غير صحيح.',
    },
  };

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
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  String _getText(String key) {
    return _texts[widget.currentLocale.languageCode]?[key] ?? _texts['en']![key]!;
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? darkBackground : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(isDark),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        _buildHeader(isDark),
                        const SizedBox(height: 60),
                        _buildSignupForm(isDark),
                        const SizedBox(height: 40),
                        _buildSignInSection(isDark),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? darkSurface : lightGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : Colors.grey[700],
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.format_quote,
              size: 24,
              color: Colors.white,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? darkSurface : lightGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: isDark ? Colors.white : Colors.grey[700],
                size: 22,
              ),
              onPressed: () => _showSettingsBottomSheet(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getText('createAccount'),
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getText('subtitle'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _getText('continueWith'),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                controller: _nameController,
                label: _getText('name'),
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
                isDark: isDark,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return _getText('nameRequired');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _emailController,
                label: _getText('email'),
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                isDark: isDark,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return _getText('emailRequired');
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return _getText('emailInvalid');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _passwordController,
                label: _getText('password'),
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: _obscurePassword,
                onToggleVisibility: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                isDark: isDark,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return _getText('passwordRequired');
                  }
                  if (value.length < 6) {
                    return _getText('passwordShort');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _confirmPasswordController,
                label: _getText('confirmPassword'),
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: _obscureConfirmPassword,
                onToggleVisibility: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
                isDark: isDark,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return _getText('confirmPasswordRequired');
                  }
                  if (value != _passwordController.text) {
                    return _getText('passwordsDontMatch');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              _buildSignupButton(isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? darkSurface : lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword ? obscureText : false,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 16,
          ),
          prefixIcon: Icon(
            icon,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            size: 22,
          ),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            onPressed: onToggleVisibility,
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildSignupButton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.white, Colors.grey[100]!]
              : [Colors.black, Colors.grey[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _signup,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: isDark ? Colors.black : Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: isDark ? Colors.black : Colors.white,
              strokeWidth: 2,
            ),
          )
              : Text(
            _getText('signup'),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInSection(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: isDark ? Colors.grey[700] : Colors.grey[300],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _getText('or'),
                style: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: isDark ? Colors.grey[700] : Colors.grey[300],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
              width: 1.5,
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                backgroundColor: isDark ? darkSurface.withOpacity(0.5) : lightGray.withOpacity(0.5),
              ),
              child: Text(
                _getText('signIn'),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildSettingsBottomSheet(context),
    );
  }

  Widget _buildSettingsBottomSheet(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isArabic = widget.currentLocale.languageCode == 'ar';

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[600] : Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      color: isDark ? Colors.white : Colors.black,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getText('settings'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildSettingItem(
                  icon: Icons.language_outlined,
                  title: isArabic ? 'اللغة' : 'Language',
                  isDark: isDark,
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: widget.currentLocale.languageCode,
                      dropdownColor: isDark ? darkSurface : Colors.white,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'ar', child: Text('العربية')),
                      ],
                      onChanged: (String? value) {
                        if (value != null) {
                          widget.onLanguageChanged(value);
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSettingItem(
                  icon: Icons.palette_outlined,
                  title: isArabic ? 'المظهر' : 'Theme',
                  isDark: isDark,
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<ThemeMode>(
                      value: widget.currentTheme,
                      dropdownColor: isDark ? darkSurface : Colors.white,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text(isArabic ? 'النظام' : 'System'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text(isArabic ? 'فاتح' : 'Light'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text(isArabic ? 'داكن' : 'Dark'),
                        ),
                      ],
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          widget.onThemeChanged(value);
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required bool isDark,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDark ? Colors.white : Colors.black,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  // دالة لحفظ بيانات المستخدم في Firestore
  Future<void> _saveUserToFirestore(User user, String name) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'profileImageUrl': null,
        'phoneNumber': null,
        'dateOfBirth': null,
        'preferences': {
          'theme': widget.currentTheme.toString(),
          'language': widget.currentLocale.languageCode,
        },
      });
      print('User data saved to Firestore successfully');
    } catch (e) {
      print('Error saving user data to Firestore: $e');
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
    });

    try {
      // إنشاء الحساب في Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // تحديث اسم المستخدم
      await userCredential.user?.updateDisplayName(_nameController.text.trim());

      // حفظ بيانات المستخدم في Firestore
      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!, _nameController.text.trim());
      }

      HapticFeedback.heavyImpact();
      _showSnackBar(_getText('signupSuccess'), Colors.green);

      // إنتظار قصير لإظهار رسالة النجاح ثم إغلاق الصفحة
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pop(context, true); // إرجاع true لإشارة نجاح العملية
      }

    } on FirebaseAuthException catch (e) {
      HapticFeedback.heavyImpact();
      String errorMessage = _getText('signupError');

      switch (e.code) {
        case 'weak-password':
          errorMessage = _getText('weakPassword');
          break;
        case 'email-already-in-use':
          errorMessage = _getText('emailInUse');
          break;
        case 'invalid-email':
          errorMessage = _getText('invalidEmail');
          break;
        default:
          errorMessage = _getText('signupError');
      }

      _showSnackBar(errorMessage, Colors.red);
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showSnackBar(_getText('signupError'), Colors.red);
      print('Signup error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}