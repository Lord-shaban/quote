import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';

import 'CreateQuotePage.dart';
import 'ProfilePage.dart';

class HomePage extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final Function(String) onLanguageChanged;
  final ThemeMode currentTheme;
  final Locale currentLocale;

  const HomePage({
    Key? key,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.currentTheme,
    required this.currentLocale,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabScaleAnimation;

  String _currentUserId = '';
  Map<String, bool> _likedQuotes = {};
  Map<String, bool> _savedQuotes = {};

  static const Color primaryColor = Color(0xFF00695C);
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF16181C);
  static const Color lightGray = Color(0xFFF7F9FA);

  Map<String, Map<String, String>> _texts = {
    'en': {
      'home': 'Home',
      'quotes': 'Quotes',
      'settings': 'Settings',
      'profile': 'Profile',
      'like': 'Like',
      'save': 'Save',
      'copy': 'Copy',
      'copied': 'Copied to clipboard!',
      'error': 'Something went wrong',
      'noQuotes': 'No quotes available',
      'loadingQuotes': 'Loading quotes...',
      'likedBy': 'liked by',
      'people': 'people',
      'person': 'person',
      'justNow': 'Just now',
      'minuteAgo': 'minute ago',
      'minutesAgo': 'minutes ago',
      'hourAgo': 'hour ago',
      'hoursAgo': 'hours ago',
      'dayAgo': 'day ago',
      'daysAgo': 'days ago',
      'anonymous': 'Anonymous',
      'createQuote': 'Create Quote',
    },
    'ar': {
      'home': 'الرئيسية',
      'quotes': 'الاقتباسات',
      'settings': 'الإعدادات',
      'profile': 'الملف الشخصي',
      'like': 'إعجاب',
      'save': 'حفظ',
      'copy': 'نسخ',
      'copied': 'تم نسخ النص!',
      'error': 'حدث خطأ ما',
      'noQuotes': 'لا توجد اقتباسات متاحة',
      'loadingQuotes': 'جاري تحميل الاقتباسات...',
      'likedBy': 'معجب بها',
      'people': 'أشخاص',
      'person': 'شخص',
      'justNow': 'الآن',
      'minuteAgo': 'منذ دقيقة',
      'minutesAgo': 'منذ دقائق',
      'hourAgo': 'منذ ساعة',
      'hoursAgo': 'منذ ساعات',
      'dayAgo': 'منذ يوم',
      'daysAgo': 'منذ أيام',
      'anonymous': 'مجهول',
      'createQuote': 'إنشاء اقتباس',
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _setupAnimations();
    _loadUserInteractions();
  }

  void _initializeUser() {
    final user = _auth.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
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

    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
    _fabAnimationController.forward();
  }

  Future<void> _loadUserInteractions() async {
    if (_currentUserId.isEmpty) return;

    try {
      // تحميل الاقتباسات المعجب بها
      final likedDocs = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('likedQuotes')
          .get();

      // تحميل الاقتباسات المحفوظة
      final savedDocs = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('savedQuotes')
          .get();

      setState(() {
        _likedQuotes = {for (var doc in likedDocs.docs) doc.id: true};
        _savedQuotes = {for (var doc in savedDocs.docs) doc.id: true};
      });
    } catch (e) {
      print('Error loading user interactions: $e');
    }
  }

  String _getText(String key) {
    return _texts[widget.currentLocale.languageCode]?[key] ?? _texts['en']![key]!;
  }

  // دالة محسنة لتحديد اتجاه النص تلقائياً
  TextDirection _detectTextDirection(String text) {
    if (text.isEmpty) return TextDirection.ltr;

    // تنظيف النص من الرموز والأرقام والمسافات
    String cleanText = text.replaceAll(RegExp(r'[^\p{L}]', unicode: true), '');

    if (cleanText.isEmpty) return TextDirection.ltr;

    // البحث عن الأحرف العربية والفارسية والأردية
    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFFFF]');
    int arabicChars = arabicRegex.allMatches(cleanText).length;

    // إذا كان هناك أحرف عربية، نحدد النسبة
    if (arabicChars > 0) {
      double arabicRatio = arabicChars / cleanText.length;

      // إذا كانت نسبة الأحرف العربية أكثر من 20% نعتبر النص عربي
      if (arabicRatio > 0.2) {
        return TextDirection.rtl;
      }
    }

    return TextDirection.ltr;
  }

  // دالة محسنة لتحديد محاذاة النص
  TextAlign _getTextAlign(TextDirection direction) {
    if (direction == TextDirection.rtl) {
      return TextAlign.right;
    } else {
      return TextAlign.left;
    }
  }

  // دالة لتحديد محاذاة النص بناءً على المحتوى
  CrossAxisAlignment _getCrossAxisAlignment(TextDirection direction) {
    if (direction == TextDirection.rtl) {
      return CrossAxisAlignment.end;
    } else {
      return CrossAxisAlignment.start;
    }
  }

  Future<void> _navigateToCreateQuote() async {
    HapticFeedback.lightImpact();

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CreateQuotePage(
          currentLocale: widget.currentLocale,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );

    // تحديث الصفحة عند العودة
    if (result != null || mounted) {
      await _loadUserInteractions();
      // إعادة تشغيل الأنيميشن للـ FAB
      _fabAnimationController.reset();
      _fabAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? darkBackground : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // البار العلوي ثابت دائماً
            _buildTopBar(isDark),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildQuotesList(isDark),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: _navigateToCreateQuote,
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(
              Icons.add,
              color: Colors.white,
              size: 24,
            ),
            label: Text(
              _getText('createQuote'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildTopBar(bool isDark) {
    final user = _auth.currentUser;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
                  Icons.format_quote,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getText('quotes'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    user?.displayName ?? _getText('anonymous'),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
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
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(
                        currentLocale: widget.currentLocale,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? darkSurface : lightGray,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: user?.photoURL != null
                        ? Image.network(
                      user!.photoURL!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(isDark),
                    )
                        : _buildDefaultAvatar(isDark),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(bool isDark) {
    return Icon(
      Icons.person,
      color: isDark ? Colors.white : Colors.grey[700],
      size: 20,
    );
  }

  Widget _buildQuotesList(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('quotes')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget(isDark);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget(isDark);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyWidget(isDark);
        }

        return RefreshIndicator(
          onRefresh: () async {
            await _loadUserInteractions();
          },
          color: primaryColor,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final quote = snapshot.data!.docs[index];
              return _buildQuoteCard(quote, isDark, index);
            },
          ),
        );
      },
    );
  }

// استبدل دالة _buildQuoteCard بهذه النسخة المحدثة:

  Widget _buildQuoteCard(QueryDocumentSnapshot quote, bool isDark, int index) {
    final data = quote.data() as Map<String, dynamic>;
    final quoteId = quote.id;
    final text = data['text'] ?? '';
    final author = data['author'] ?? _getText('anonymous');
    final createdAt = data['createdAt'] as Timestamp?;
    final likesCount = data['likesCount'] ?? 0;
    final isLiked = _likedQuotes[quoteId] ?? false;
    final isSaved = _savedQuotes[quoteId] ?? false;

    // تحديد اتجاه النص تلقائياً
    final textDirection = _detectTextDirection(text);
    final textAlign = _getTextAlign(textDirection);
    final authorDirection = _detectTextDirection(author);

    return Container(
      margin: EdgeInsets.only(
        bottom: 20,
        top: index == 0 ? 20 : 0,
      ),
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // الوقت في الأعلى (تصميم جديد)
            if (createdAt != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.grey[800] : Colors.grey[100])?.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Quote Text with auto direction detection
            Container(
              width: double.infinity,
              child: Directionality(
                textDirection: textDirection,
                child: SelectableText(
                  text,
                  textAlign: textAlign,
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

            // Author only (الوقت تم نقله للأعلى)
            Container(
              width: double.infinity,
              child: Directionality(
                textDirection: authorDirection,
                child: Text(
                  '— $author',
                  textAlign: _getTextAlign(authorDirection),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Actions Row
            Row(
              children: [
                // Like Button
                _buildActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: likesCount.toString(),
                  color: isLiked ? Colors.red : (isDark ? Colors.grey[400]! : Colors.grey[600]!),
                  onTap: () => _toggleLike(quoteId, isLiked),
                  isDark: isDark,
                ),

                const SizedBox(width: 20),

                // Save Button
                _buildActionButton(
                  icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                  label: _getText('save'),
                  color: isSaved ? primaryColor : (isDark ? Colors.grey[400]! : Colors.grey[600]!),
                  onTap: () => _toggleSave(quoteId, isSaved, text, author),
                  isDark: isDark,
                ),

                const Spacer(),

                // Copy Button
                _buildActionButton(
                  icon: Icons.copy_outlined,
                  label: _getText('copy'),
                  color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                  onTap: () => _copyQuote(text, author),
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: primaryColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            _getText('loadingQuotes'),
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _getText('error'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.format_quote,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _getText('noQuotes'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike(String quoteId, bool isCurrentlyLiked) async {
    if (_currentUserId.isEmpty) return;

    HapticFeedback.lightImpact();

    try {
      final batch = _firestore.batch();
      final quoteRef = _firestore.collection('quotes').doc(quoteId);
      final userLikeRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('likedQuotes')
          .doc(quoteId);

      if (isCurrentlyLiked) {
        // Remove like
        batch.update(quoteRef, {'likesCount': FieldValue.increment(-1)});
        batch.delete(userLikeRef);
        setState(() {
          _likedQuotes[quoteId] = false;
        });
      } else {
        // Add like
        batch.update(quoteRef, {'likesCount': FieldValue.increment(1)});
        batch.set(userLikeRef, {
          'quoteId': quoteId,
          'likedAt': FieldValue.serverTimestamp(),
        });
        setState(() {
          _likedQuotes[quoteId] = true;
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error toggling like: $e');
      // Revert optimistic update
      setState(() {
        _likedQuotes[quoteId] = isCurrentlyLiked;
      });
    }
  }

  Future<void> _toggleSave(String quoteId, bool isCurrentlySaved, String text, String author) async {
    if (_currentUserId.isEmpty) return;

    HapticFeedback.lightImpact();

    try {
      final userSaveRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('savedQuotes')
          .doc(quoteId);

      if (isCurrentlySaved) {
        // Remove save
        await userSaveRef.delete();
        setState(() {
          _savedQuotes[quoteId] = false;
        });
      } else {
        // Add save
        await userSaveRef.set({
          'quoteId': quoteId,
          'text': text,
          'author': author,
          'savedAt': FieldValue.serverTimestamp(),
        });
        setState(() {
          _savedQuotes[quoteId] = true;
        });
      }
    } catch (e) {
      print('Error toggling save: $e');
      // Revert optimistic update
      setState(() {
        _savedQuotes[quoteId] = isCurrentlySaved;
      });
    }
  }

  void _copyQuote(String text, String author) {
    final fullQuote = '"$text"\n— $author';
    Clipboard.setData(ClipboardData(text: fullQuote));
    HapticFeedback.lightImpact();
    _showSnackBar(_getText('copied'), Colors.green);
  }

  String _formatTime(Timestamp timestamp) {
    final now = DateTime.now();
    final time = timestamp.toDate();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return _getText('justNow');
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return minutes == 1
          ? '1 ${_getText('minuteAgo')}'
          : '$minutes ${_getText('minutesAgo')}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours == 1
          ? '1 ${_getText('hourAgo')}'
          : '$hours ${_getText('hoursAgo')}';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return days == 1
          ? '1 ${_getText('dayAgo')}'
          : '$days ${_getText('daysAgo')}';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
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
    _scrollController.dispose();
    super.dispose();
  }
}