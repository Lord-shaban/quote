import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  final Locale currentLocale;

  const ProfilePage({
    Key? key,
    required this.currentLocale,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _bioController = TextEditingController();

  late AnimationController _animationController;
  late AnimationController _tabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _tabScaleAnimation;

  String _currentUserId = '';
  int _selectedTabIndex = 0;
  Map<String, dynamic> _userStats = {};
  String _userBio = '';
  String _userProfileImage = '';
  bool _isLoadingImage = false;
  bool _isEditingBio = false;

  // Cloudinary Configuration
  static const String cloudName = 'dmksezjjc';
  static const String uploadPreset = 'COVE_APP';

  static const Color primaryColor = Color(0xFF00695C);
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF16181C);
  static const Color lightGray = Color(0xFFF7F9FA);

  Map<String, Map<String, String>> _texts = {
    'en': {
      'profile': 'Profile',
      'myQuotes': 'My Quotes',
      'likedQuotes': 'Liked Quotes',
      'savedQuotes': 'Saved Quotes',
      'settings': 'Settings',
      'signOut': 'Sign Out',
      'quotes': 'Quotes',
      'likes': 'Likes',
      'saves': 'Saves',
      'followers': 'Followers',
      'following': 'Following',
      'edit': 'Edit',
      'anonymous': 'Anonymous',
      'noQuotes': 'No quotes yet',
      'noLikedQuotes': 'No liked quotes yet',
      'noSavedQuotes': 'No saved quotes yet',
      'createFirstQuote': 'Create your first quote',
      'exploreQuotes': 'Explore quotes to like',
      'saveQuotes': 'Save quotes you love',
      'member': 'Member since',
      'confirmSignOut': 'Are you sure you want to sign out?',
      'cancel': 'Cancel',
      'signOutConfirm': 'Sign Out',
      'signedOut': 'Signed out successfully',
      'error': 'Something went wrong',
      'loading': 'Loading...',
      'delete': 'Delete',
      'confirmDelete': 'Are you sure you want to delete this quote?',
      'deleted': 'Quote deleted successfully',
      'justNow': 'Just now',
      'minuteAgo': 'minute ago',
      'minutesAgo': 'minutes ago',
      'hourAgo': 'hour ago',
      'hoursAgo': 'hours ago',
      'dayAgo': 'day ago',
      'daysAgo': 'days ago',
      'copy': 'Copy',
      'copied': 'Copied to clipboard!',
      'editBio': 'Edit Bio',
      'bio': 'Bio',
      'noBio': 'No bio yet',
      'addBio': 'Add a bio to tell others about yourself',
      'save': 'Save',
      'bioUpdated': 'Bio updated successfully',
      'profileUpdated': 'Profile updated successfully',
      'uploadingImage': 'Uploading image...',
      'selectImage': 'Select Image',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'bioHint': 'Tell others about yourself...',
    },
    'ar': {
      'profile': 'الملف الشخصي',
      'myQuotes': 'اقتباساتي',
      'likedQuotes': 'الاقتباسات المعجب بها',
      'savedQuotes': 'الاقتباسات المحفوظة',
      'settings': 'الإعدادات',
      'signOut': 'تسجيل الخروج',
      'quotes': 'اقتباسات',
      'likes': 'إعجابات',
      'saves': 'محفوظات',
      'followers': 'متابعين',
      'following': 'متابَعين',
      'edit': 'تعديل',
      'anonymous': 'مجهول',
      'noQuotes': 'لا توجد اقتباسات بعد',
      'noLikedQuotes': 'لا توجد اقتباسات معجب بها بعد',
      'noSavedQuotes': 'لا توجد اقتباسات محفوظة بعد',
      'createFirstQuote': 'أنشئ اقتباسك الأول',
      'exploreQuotes': 'استكشف الاقتباسات للإعجاب بها',
      'saveQuotes': 'احفظ الاقتباسات التي تحبها',
      'member': 'عضو منذ',
      'confirmSignOut': 'هل أنت متأكد من تسجيل الخروج؟',
      'cancel': 'إلغاء',
      'signOutConfirm': 'تسجيل الخروج',
      'signedOut': 'تم تسجيل الخروج بنجاح',
      'error': 'حدث خطأ ما',
      'loading': 'جاري التحميل...',
      'delete': 'حذف',
      'confirmDelete': 'هل أنت متأكد من حذف هذا الاقتباس؟',
      'deleted': 'تم حذف الاقتباس بنجاح',
      'justNow': 'الآن',
      'minuteAgo': 'منذ دقيقة',
      'minutesAgo': 'منذ دقائق',
      'hourAgo': 'منذ ساعة',
      'hoursAgo': 'منذ ساعات',
      'dayAgo': 'منذ يوم',
      'daysAgo': 'منذ أيام',
      'copy': 'نسخ',
      'copied': 'تم نسخ النص!',
      'editBio': 'تعديل النبذة',
      'bio': 'النبذة الشخصية',
      'noBio': 'لا توجد نبذة شخصية',
      'addBio': 'أضف نبذة شخصية لتعريف الآخرين بك',
      'save': 'حفظ',
      'bioUpdated': 'تم تحديث النبذة بنجاح',
      'profileUpdated': 'تم تحديث الملف الشخصي بنجاح',
      'uploadingImage': 'جاري رفع الصورة...',
      'selectImage': 'اختر صورة',
      'camera': 'الكاميرا',
      'gallery': 'المعرض',
      'bioHint': 'أخبر الآخرين عن نفسك...',
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _setupAnimations();
    _loadUserStats();
    _loadUserProfile();
  }

  void _initializeUser() {
    final user = _auth.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      print('Current User ID: $_currentUserId');
    } else {
      print('No user found');
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
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

    _tabScaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _tabAnimationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadUserProfile() async {
    if (_currentUserId.isEmpty) return;

    try {
      final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _userBio = data['bio'] ?? '';
          _userProfileImage = data['profileImage'] ?? '';
        });
        _bioController.text = _userBio;
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _loadUserStats() async {
    if (_currentUserId.isEmpty) {
      print('User ID is empty, cannot load stats');
      return;
    }

    try {
      print('Loading stats for user: $_currentUserId');

      // عدد الاقتباسات التي كتبها المستخدم
      final myQuotesSnapshot = await _firestore
          .collection('quotes')
          .where('createdBy', isEqualTo: _currentUserId)
          .get();

      print('My quotes count: ${myQuotesSnapshot.docs.length}');

      // عدد الاقتباسات المعجب بها
      final likedQuotesSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('likedQuotes')
          .get();

      print('Liked quotes count: ${likedQuotesSnapshot.docs.length}');

      // عدد الاقتباسات المحفوظة
      final savedQuotesSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('savedQuotes')
          .get();

      print('Saved quotes count: ${savedQuotesSnapshot.docs.length}');

      // حساب مجموع الإعجابات على اقتباسات المستخدم
      int totalLikes = 0;
      for (var doc in myQuotesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final likesCount = data['likesCount'] as int? ?? 0;
        totalLikes += likesCount;
        print('Quote ${doc.id} has $likesCount likes');
      }

      print('Total likes: $totalLikes');

      setState(() {
        _userStats = {
          'quotesCount': myQuotesSnapshot.docs.length,
          'likedCount': likedQuotesSnapshot.docs.length,
          'savedCount': savedQuotesSnapshot.docs.length,
          'totalLikes': totalLikes,
        };
      });
    } catch (e) {
      print('Error loading user stats: $e');
    }
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    try {
      setState(() {
        _isLoadingImage = true;
      });

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
      );

      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = 'profile_images';

      final file = await http.MultipartFile.fromPath('file', imageFile.path);
      request.files.add(file);

      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseString);
        return jsonResponse['secure_url'];
      } else {
        print('Upload failed: $responseString');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    } finally {
      setState(() {
        _isLoadingImage = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        final String? imageUrl = await _uploadImageToCloudinary(imageFile);

        if (imageUrl != null) {
          await _updateProfileImage(imageUrl);
        } else {
          _showErrorSnackBar();
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorSnackBar();
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? darkSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            _getText('selectImage'),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(ImageSource.camera),
              icon: Icon(Icons.camera_alt, color: primaryColor),
              label: Text(
                _getText('camera'),
                style: TextStyle(color: primaryColor),
              ),
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
              icon: Icon(Icons.photo_library, color: primaryColor),
              label: Text(
                _getText('gallery'),
                style: TextStyle(color: primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProfileImage(String imageUrl) async {
    try {
      await _firestore.collection('users').doc(_currentUserId).set({
        'profileImage': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _userProfileImage = imageUrl;
      });

      _showSuccessSnackBar(_getText('profileUpdated'));
    } catch (e) {
      print('Error updating profile image: $e');
      _showErrorSnackBar();
    }
  }

  Future<void> _updateBio() async {
    try {
      final newBio = _bioController.text.trim();

      await _firestore.collection('users').doc(_currentUserId).set({
        'bio': newBio,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _userBio = newBio;
        _isEditingBio = false;
      });

      _showSuccessSnackBar(_getText('bioUpdated'));
    } catch (e) {
      print('Error updating bio: $e');
      _showErrorSnackBar();
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: primaryColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _getText('error'),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _getText(String key) {
    return _texts[widget.currentLocale.languageCode]?[key] ?? _texts['en']![key]!;
  }

  // دالة محسنة لتحديد اتجاه النص تلقائياً
  TextDirection _detectTextDirection(String text) {
    if (text.isEmpty) return TextDirection.ltr;

    String cleanText = text.replaceAll(RegExp(r'[^\p{L}]', unicode: true), '');
    if (cleanText.isEmpty) return TextDirection.ltr;

    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFFFF]');
    int arabicChars = arabicRegex.allMatches(cleanText).length;

    if (arabicChars > 0) {
      double arabicRatio = arabicChars / cleanText.length;
      if (arabicRatio > 0.2) {
        return TextDirection.rtl;
      }
    }

    return TextDirection.ltr;
  }

  TextAlign _getTextAlign(TextDirection direction) {
    return direction == TextDirection.rtl ? TextAlign.right : TextAlign.left;
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
                  child: Column(
                    children: [
                      _buildProfileHeader(isDark),
                      _buildTabBar(isDark),
                      Expanded(
                        child: _buildTabContent(isDark),
                      ),
                    ],
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
          const SizedBox(width: 16),
          Text(
            _getText('profile'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: isDark ? darkSurface : lightGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.logout_outlined,
                color: Colors.red[400],
                size: 22,
              ),
              onPressed: () => _showSignOutDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    final user = _auth.currentUser;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // صورة البروفايل مع إمكانية التعديل
          GestureDetector(
            onTap: _pickAndUploadImage,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(47),
                    child: _isLoadingImage
                        ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                        : _userProfileImage.isNotEmpty
                        ? Image.network(
                      _userProfileImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(isDark),
                    )
                        : _buildDefaultAvatar(isDark),
                  ),
                ),

                // أيقونة التعديل
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? darkBackground : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // اسم المستخدم
          Text(
            user?.displayName ?? _getText('anonymous'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),

          const SizedBox(height: 8),

          // النبذة الشخصية
          _buildBioSection(isDark),

          const SizedBox(height: 8),

          // تاريخ الانضمام
          if (user?.metadata.creationTime != null)
            Text(
              '${_getText('member')} ${_formatDate(user!.metadata.creationTime!)}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),

          const SizedBox(height: 24),

          // الإحصائيات
          _buildStatsRow(isDark),
        ],
      ),
    );
  }

  Widget _buildBioSection(bool isDark) {
    if (_isEditingBio) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? darkSurface : lightGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            TextField(
              controller: _bioController,
              maxLines: 3,
              maxLength: 150,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: _getText('bioHint'),
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                border: InputBorder.none,
                counterStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditingBio = false;
                      _bioController.text = _userBio;
                    });
                  },
                  child: Text(
                    _getText('cancel'),
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _updateBio,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _getText('save'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isEditingBio = true;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? darkSurface.withOpacity(0.5) : lightGray.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _userBio.isEmpty ? _getText('addBio') : _userBio,
                style: TextStyle(
                  fontSize: 14,
                  color: _userBio.isEmpty
                      ? (isDark ? Colors.grey[500] : Colors.grey[500])
                      : (isDark ? Colors.grey[300] : Colors.grey[700]),
                  fontStyle: _userBio.isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.edit_outlined,
              size: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 50,
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          title: _getText('quotes'),
          value: '${_userStats['quotesCount'] ?? 0}',
          isDark: isDark,
        ),
        _buildStatItem(
          title: _getText('likes'),
          value: '${_userStats['totalLikes'] ?? 0}',
          isDark: isDark,
        ),
        _buildStatItem(
          title: _getText('saves'),
          value: '${_userStats['savedCount'] ?? 0}',
          isDark: isDark,
        ),
      ],
    );
  }
  Widget _buildStatItem({
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(bool isDark) {
    List<String> tabs = [
      _getText('myQuotes'),
      _getText('likedQuotes'),
      _getText('savedQuotes'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? darkSurface : lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          int index = entry.key;
          String tab = entry.value;
          bool isSelected = _selectedTabIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedTabIndex = index;
                });
                _tabAnimationController.forward().then((_) {
                  _tabAnimationController.reverse();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(bool isDark) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildMyQuotes(isDark);
      case 1:
        return _buildLikedQuotes(isDark);
      case 2:
        return _buildSavedQuotes(isDark);
      default:
        return _buildMyQuotes(isDark);
    }
  }

  // الحل الرئيسي: تم إزالة orderBy من الاستعلام لتجنب مشكلة الفهرس المركب
  Widget _buildMyQuotes(bool isDark) {
    print('Building my quotes for user: $_currentUserId');

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('quotes')
          .where('createdBy', isEqualTo: _currentUserId)
      // تم إزالة orderBy لتجنب مشكلة الفهرس المركب
          .snapshots(),
      builder: (context, snapshot) {
        print('Stream builder state: ${snapshot.connectionState}');
        print('Has error: ${snapshot.hasError}');
        if (snapshot.hasError) {
          print('Error: ${snapshot.error}');
        }
        print('Has data: ${snapshot.hasData}');
        if (snapshot.hasData) {
          print('Documents count: ${snapshot.data!.docs.length}');
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(isDark);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget(isDark);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyWidget(
            isDark,
            _getText('noQuotes'),
            _getText('createFirstQuote'),
            Icons.format_quote,
          );
        }

        // ترتيب البيانات يدوياً بعد استلامها
        List<QueryDocumentSnapshot> sortedDocs = snapshot.data!.docs.toList();
        sortedDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          final aTimestamp = aData['createdAt'] as Timestamp?;
          final bTimestamp = bData['createdAt'] as Timestamp?;

          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;

          return bTimestamp.compareTo(aTimestamp); // ترتيب تنازلي (الأحدث أولاً)
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            final quote = sortedDocs[index];
            return _buildQuoteCard(quote, isDark, canDelete: true);
          },
        );
      },
    );
  }

  Widget _buildLikedQuotes(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('likedQuotes')
          .orderBy('likedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget(isDark);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget(isDark);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyWidget(
            isDark,
            _getText('noLikedQuotes'),
            _getText('exploreQuotes'),
            Icons.favorite_border,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final likedQuote = snapshot.data!.docs[index];
            final quoteId = likedQuote.id;

            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('quotes').doc(quoteId).get(),
              builder: (context, quoteSnapshot) {
                if (!quoteSnapshot.hasData || !quoteSnapshot.data!.exists) {
                  return const SizedBox.shrink();
                }

                return _buildQuoteCard(quoteSnapshot.data!, isDark);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSavedQuotes(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('savedQuotes')
          .orderBy('savedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget(isDark);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget(isDark);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyWidget(
            isDark,
            _getText('noSavedQuotes'),
            _getText('saveQuotes'),
            Icons.bookmark_border,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final savedQuote = snapshot.data!.docs[index];
            final data = savedQuote.data() as Map<String, dynamic>;

            return _buildSavedQuoteCard(data, isDark);
          },
        );
      },
    );
  }

  Widget _buildQuoteCard(DocumentSnapshot quote, bool isDark, {bool canDelete = false}) {
    final data = quote.data() as Map<String, dynamic>;
    final text = data['text'] ?? '';
    final author = data['author'] ?? _getText('anonymous');
    final createdAt = data['createdAt'] as Timestamp?;
    final likesCount = data['likesCount'] ?? 0;

    final textDirection = _detectTextDirection(text);
    final textAlign = _getTextAlign(textDirection);
    final authorDirection = _detectTextDirection(author);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with time and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (createdAt != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.grey[800] : Colors.grey[100])?.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatTime(createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),

                Row(
                  children: [
                    if (likesCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 14,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$likesCount',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (canDelete) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showDeleteDialog(quote.id),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Quote text
            Directionality(
              textDirection: textDirection,
              child: Text(
                text,
                textAlign: textAlign,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Author
            Directionality(
              textDirection: authorDirection,
              child: Text(
                '— $author',
                textAlign: _getTextAlign(authorDirection),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Copy button
            GestureDetector(
              onTap: () => _copyQuote(text, author),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.grey[700] : Colors.grey[100])?.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.copy_outlined,
                      size: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getText('copy'),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSavedQuoteCard(Map<String, dynamic> data, bool isDark) {
    final text = data['text'] ?? '';
    final author = data['author'] ?? _getText('anonymous');
    final savedAt = data['savedAt'] as Timestamp?;

    final textDirection = _detectTextDirection(text);
    final textAlign = _getTextAlign(textDirection);
    final authorDirection = _detectTextDirection(author);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with saved time
            if (savedAt != null)
              Container(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmark,
                        size: 14,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(savedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (savedAt != null) const SizedBox(height: 16),

            // Quote text
            Directionality(
              textDirection: textDirection,
              child: Text(
                text,
                textAlign: textAlign,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Author
            Directionality(
              textDirection: authorDirection,
              child: Text(
                '— $author',
                textAlign: _getTextAlign(authorDirection),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Copy button
            GestureDetector(
              onTap: () => _copyQuote(text, author),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.grey[700] : Colors.grey[100])?.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.copy_outlined,
                      size: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getText('copy'),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(bool isDark, String message, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                icon,
                size: 40,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
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
          ),
          const SizedBox(height: 16),
          Text(
            _getText('loading'),
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
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              _getText('error'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(Timestamp timestamp) {
    final now = DateTime.now();
    final dateTime = timestamp.toDate();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return _getText('justNow');
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      if (minutes == 1) {
        return '1 ${_getText('minuteAgo')}';
      } else {
        return '$minutes ${_getText('minutesAgo')}';
      }
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      if (hours == 1) {
        return '1 ${_getText('hourAgo')}';
      } else {
        return '$hours ${_getText('hoursAgo')}';
      }
    } else {
      final days = difference.inDays;
      if (days == 1) {
        return '1 ${_getText('dayAgo')}';
      } else {
        return '$days ${_getText('daysAgo')}';
      }
    }
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${months[dateTime.month - 1]} ${dateTime.year}';
  }

  void _copyQuote(String text, String author) {
    final quoteToCopy = '$text\n\n— $author';
    Clipboard.setData(ClipboardData(text: quoteToCopy));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _getText('copied'),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: primaryColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? darkSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            _getText('confirmSignOut'),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _getText('cancel'),
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _signOut();
              },
              child: Text(
                _getText('signOutConfirm'),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(String quoteId) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? darkSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            _getText('confirmDelete'),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _getText('cancel'),
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteQuote(quoteId);
              },
              child: Text(
                _getText('delete'),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getText('signedOut'),
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: primaryColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      // العودة للشاشة الرئيسية أو شاشة تسجيل الدخول
      Navigator.of(context).popUntil((route) => route.isFirst);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getText('error'),
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _deleteQuote(String quoteId) async {
    try {
      await _firestore.collection('quotes').doc(quoteId).delete();

      // إعادة تحميل الإحصائيات
      await _loadUserStats();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getText('deleted'),
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: primaryColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getText('error'),
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabAnimationController.dispose();
    super.dispose();
  }
}