import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class CreateQuotePage extends StatefulWidget {
  final Locale currentLocale;

  const CreateQuotePage({
    Key? key,
    required this.currentLocale,
  }) : super(key: key);

  @override
  _CreateQuotePageState createState() => _CreateQuotePageState();
}

class _CreateQuotePageState extends State<CreateQuotePage>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _quoteController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final FocusNode _quoteFocusNode = FocusNode();
  final FocusNode _authorFocusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;

  static const Color primaryColor = Color(0xFF00695C);
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF16181C);
  static const Color lightGray = Color(0xFFF7F9FA);

  Map<String, Map<String, String>> _texts = {
    'en': {
      'createQuote': 'Create Quote',
      'quote': 'Quote',
      'author': 'Author',
      'quotePlaceholder': 'Enter your quote here...',
      'authorPlaceholder': 'Enter author name (optional)',
      'publish': 'Publish Quote',
      'publishing': 'Publishing...',
      'success': 'Quote published successfully!',
      'error': 'Failed to publish quote',
      'quoteRequired': 'Quote text is required',
      'quoteMinLength': 'Quote must be at least 10 characters',
      'quoteMaxLength': 'Quote must not exceed 500 characters',
      'anonymous': 'Anonymous',
      'cancel': 'Cancel',
      'unsavedChanges': 'Unsaved Changes',
      'unsavedMessage': 'You have unsaved changes. Are you sure you want to leave?',
      'leave': 'Leave',
      'stay': 'Stay',
      'characterCount': 'characters',
      'preview': 'Preview',
    },
    'ar': {
      'createQuote': 'إنشاء اقتباس',
      'quote': 'الاقتباس',
      'author': 'المؤلف',
      'quotePlaceholder': 'أدخل الاقتباس هنا...',
      'authorPlaceholder': 'أدخل اسم المؤلف (اختياري)',
      'publish': 'نشر الاقتباس',
      'publishing': 'جاري النشر...',
      'success': 'تم نشر الاقتباس بنجاح!',
      'error': 'فشل في نشر الاقتباس',
      'quoteRequired': 'نص الاقتباس مطلوب',
      'quoteMinLength': 'يجب أن يكون الاقتباس 10 أحرف على الأقل',
      'quoteMaxLength': 'يجب ألا يتجاوز الاقتباس 500 حرف',
      'anonymous': 'لقائله',
      'cancel': 'إلغاء',
      'unsavedChanges': 'تغييرات غير محفوظة',
      'unsavedMessage': 'لديك تغييرات غير محفوظة. هل أنت متأكد من أنك تريد المغادرة؟',
      'leave': 'مغادرة',
      'stay': 'البقاء',
      'characterCount': 'حرف',
      'preview': 'معاينة',
    },
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupTextControllerListeners();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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

  void _setupTextControllerListeners() {
    _quoteController.addListener(() {
      setState(() {});
    });
    _authorController.addListener(() {
      setState(() {});
    });
  }

  String _getText(String key) {
    return _texts[widget.currentLocale.languageCode]?[key] ?? _texts['en']![key]!;
  }

  bool get _hasUnsavedChanges {
    return _quoteController.text.trim().isNotEmpty || _authorController.text.trim().isNotEmpty;
  }

  // دالة لتحديد اتجاه النص تلقائياً (نفس الدالة من HomePage)
  TextDirection _detectTextDirection(String text) {
    // إزالة المسافات والرموز للحصول على النص الفعلي
    String cleanText = text.replaceAll(RegExp(r'[^\w\u0600-\u06FF]'), '');

    if (cleanText.isEmpty) return TextDirection.ltr;

    // التحقق من وجود أحرف عربية
    bool hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(cleanText);

    if (hasArabic) {
      // حساب نسبة الأحرف العربية
      int arabicChars = RegExp(r'[\u0600-\u06FF]').allMatches(cleanText).length;
      double arabicRatio = arabicChars / cleanText.length;

      // إذا كانت نسبة الأحرف العربية أكثر من 30% نعتبر النص عربي
      return arabicRatio > 0.3 ? TextDirection.rtl : TextDirection.ltr;
    }

    return TextDirection.ltr;
  }

  // دالة لتحديد إذا كان النص عربي (للمؤلف المجهول)
  bool _isTextArabic(String text) {
    if (text.trim().isEmpty) return false;

    String cleanText = text.replaceAll(RegExp(r'[^\w\u0600-\u06FF]'), '');
    if (cleanText.isEmpty) return false;

    // التحقق من وجود أحرف عربية
    bool hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(cleanText);

    if (hasArabic) {
      // حساب نسبة الأحرف العربية
      int arabicChars = RegExp(r'[\u0600-\u06FF]').allMatches(cleanText).length;
      double arabicRatio = arabicChars / cleanText.length;

      // إذا كانت نسبة الأحرف العربية أكثر من 30% نعتبر النص عربي
      return arabicRatio > 0.3;
    }

    return false;
  }

  // دالة للحصول على النص المناسب للمؤلف المجهول حسب لغة النص
  String _getAnonymousText(String quoteText) {
    return _isTextArabic(quoteText) ? 'لقائله' : 'Anonymous';
  }

  // دالة لتحديد محاذاة النص حسب الاتجاه
  TextAlign _getTextAlign(TextDirection direction) {
    return direction == TextDirection.rtl ? TextAlign.right : TextAlign.left;
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isArabic = widget.currentLocale.languageCode == 'ar';

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (!didPop && _hasUnsavedChanges) {
          final shouldPop = await _showUnsavedChangesDialog();
          if (shouldPop == true && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? darkBackground : Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(isDark, isArabic),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildForm(isDark, isArabic),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark, bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? darkSurface : lightGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                isArabic ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                color: isDark ? Colors.white : Colors.grey[700],
                size: 20,
              ),
              onPressed: () async {
                if (_hasUnsavedChanges) {
                  final shouldPop = await _showUnsavedChangesDialog();
                  if (shouldPop == true && context.mounted) {
                    Navigator.of(context).pop();
                  }
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
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
                    Icons.edit_outlined,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _getText('createQuote'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isDark, bool isArabic) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),

          // Quote Input Section
          _buildInputSection(
            title: _getText('quote'),
            isDark: isDark,
            child: _buildQuoteInput(isDark, isArabic),
          ),

          const SizedBox(height: 32),

          // Author Input Section
          _buildInputSection(
            title: _getText('author'),
            isDark: isDark,
            child: _buildAuthorInput(isDark, isArabic),
          ),

          const SizedBox(height: 40),

          // Preview Section
          if (_quoteController.text.trim().isNotEmpty)
            _buildPreviewSection(isDark, isArabic),

          const SizedBox(height: 40),

          // Publish Button
          _buildPublishButton(isDark),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInputSection({
    required String title,
    required bool isDark,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildQuoteInput(bool isDark, bool isArabic) {
    final characterCount = _quoteController.text.length;
    final maxLength = 500;
    final isOverLimit = characterCount > maxLength;

    // تحديد اتجاه النص تلقائياً
    final textDirection = _quoteController.text.trim().isNotEmpty
        ? _detectTextDirection(_quoteController.text)
        : (isArabic ? TextDirection.rtl : TextDirection.ltr);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _quoteFocusNode.hasFocus
                  ? primaryColor
                  : isDark ? Colors.grey[700]! : Colors.grey[300]!,
              width: _quoteFocusNode.hasFocus ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Directionality(
            textDirection: textDirection,
            child: TextField(
              controller: _quoteController,
              focusNode: _quoteFocusNode,
              maxLines: 8,
              textDirection: textDirection,
              textAlign: _getTextAlign(textDirection),
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: _getText('quotePlaceholder'),
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$characterCount/$maxLength ${_getText('characterCount')}',
          style: TextStyle(
            fontSize: 12,
            color: isOverLimit
                ? Colors.red
                : isDark ? Colors.grey[500] : Colors.grey[600],
            fontWeight: isOverLimit ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthorInput(bool isDark, bool isArabic) {
    // تحديد اتجاه النص تلقائياً
    final textDirection = _authorController.text.trim().isNotEmpty
        ? _detectTextDirection(_authorController.text)
        : (isArabic ? TextDirection.rtl : TextDirection.ltr);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _authorFocusNode.hasFocus
              ? primaryColor
              : isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: _authorFocusNode.hasFocus ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Directionality(
        textDirection: textDirection,
        child: TextField(
          controller: _authorController,
          focusNode: _authorFocusNode,
          textDirection: textDirection,
          textAlign: _getTextAlign(textDirection),
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: _getText('authorPlaceholder'),
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewSection(bool isDark, bool isArabic) {
    final quoteText = _quoteController.text.trim();
    // استخدام دالة الحصول على النص المناسب للمؤلف المجهول حسب لغة النص
    final authorText = _authorController.text.trim().isEmpty
        ? _getAnonymousText(quoteText)
        : _authorController.text.trim();

    // تحديد اتجاه النص تلقائياً
    final quoteDirection = _detectTextDirection(quoteText);
    final authorDirection = _detectTextDirection(authorText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getText('preview'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Quote Text with auto direction detection
              Container(
                width: double.infinity,
                child: Directionality(
                  textDirection: quoteDirection,
                  child: SelectableText(
                    quoteText,
                    textAlign: _getTextAlign(quoteDirection),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.6,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Author with auto direction detection
              Directionality(
                textDirection: authorDirection,
                child: Text(
                  '— $authorText',
                  textAlign: _getTextAlign(authorDirection),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPublishButton(bool isDark) {
    final canPublish = _quoteController.text.trim().length >= 10 &&
        _quoteController.text.trim().length <= 500 &&
        !_isLoading;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: canPublish
            ? LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: canPublish ? null : (isDark ? Colors.grey[700] : Colors.grey[300]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: canPublish
            ? [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canPublish ? _publishQuote : null,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Text(
              _isLoading ? _getText('publishing') : _getText('publish'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: canPublish ? Colors.white : Colors.grey[500],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _publishQuote() async {
    if (_isLoading) return;

    final quoteText = _quoteController.text.trim();
    if (quoteText.isEmpty || quoteText.length < 10 || quoteText.length > 500) {
      _showSnackBar(_getText('quoteRequired'), Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // استخدام دالة الحصول على النص المناسب للمؤلف المجهول حسب لغة النص
      final authorText = _authorController.text.trim().isEmpty
          ? _getAnonymousText(quoteText)
          : _authorController.text.trim();

      await _firestore.collection('quotes').add({
        'text': quoteText,
        'author': authorText,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
        'likesCount': 0,
        'isActive': true,
      });

      HapticFeedback.lightImpact();
      _showSnackBar(_getText('success'), Colors.green);

      // Clear the form
      _quoteController.clear();
      _authorController.clear();

      // Navigate back after a short delay
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error publishing quote: $e');
      _showSnackBar(_getText('error'), Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool?> _showUnsavedChangesDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        bool isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? darkSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            _getText('unsavedChanges'),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            _getText('unsavedMessage'),
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                _getText('stay'),
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                _getText('leave'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _quoteController.dispose();
    _authorController.dispose();
    _quoteFocusNode.dispose();
    _authorFocusNode.dispose();
    super.dispose();
  }
}