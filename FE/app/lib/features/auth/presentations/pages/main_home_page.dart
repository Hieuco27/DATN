// lib/features/auth/presentations/pages/main_home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:book_tech/core/theme/app_palette.dart';
import 'package:book_tech/features/auth/data/models/appbanner.dart';
import 'package:book_tech/features/auth/presentations/widgets/home/banner_item.dart';
import 'package:book_tech/features/auth/presentations/widgets/home/page_indicator.dart';
import 'package:book_tech/features/auth/presentations/widgets/home/new_navigation.dart'
    as new_navigation;
import 'package:book_tech/features/auth/presentations/widgets/document/document.dart';
import '../providers/document_provider.dart';
import '../widgets/document/type_section.dart';
import '../pages/type_category_page.dart';
import '../pages/book_page.dart';
import '../pages/magazine_page.dart';
import '../pages/newspaper_page.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  int _currentBannerIndex = 0;
  late PageController _bannerPageController;
  late Timer _timer;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isSearchFocused = false;

  // Trong MainHomePage, sửa initState:
  @override
  void initState() {
    super.initState();
    _bannerPageController = PageController(viewportFraction: 0.8);
    _startAutoScroll();

    // Listen to focus changes
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });

    // Load documents after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      docProvider.loadPreviews(context); // Truyền context
    });
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_bannerPageController.hasClients) {
        int nextPage =
            (_currentBannerIndex + 1) % AppBanner.appBannerList.length;
        _bannerPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    // TODO: Implement search functionality
    print('🔍 Searching for: $query');

    // Hiện tại chỉ hiển thị snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tìm kiếm: "$query"'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color.fromARGB(255, 34, 133, 225),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showNavigationModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: const Color.fromARGB(255, 255, 255, 255),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(2, 0),
                ),
              ],
            ),
            child: const new_navigation.NavigationDrawer(),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(-1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
          child: child,
        );
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _bannerPageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 34, 133, 225),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 24),
          onPressed: () {
            _showNavigationModal(context);
          },
        ),
        title: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            onSubmitted: (value) {
              _performSearch(value);
            },
            onTap: () {
              // Có thể thêm logic khi tap vào search box
            },
            decoration: InputDecoration(
              hintText: 'Tìm kiếm sách, tác giả...',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
              prefixIcon: Icon(
                Icons.search,
                color: _isSearchFocused
                    ? const Color.fromARGB(255, 34, 133, 225)
                    : Colors.grey[600],
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _searchFocusNode.unfocus();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            textInputAction: TextInputAction.search,
            keyboardType: TextInputType.text,
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () {
              // TODO: Implement profile
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 16.0),
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: PageView.builder(
                      controller: _bannerPageController,
                      itemCount: AppBanner.appBannerList.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentBannerIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return BannerItem(index: index);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  PageIndicator(
                    currentPage: _currentBannerIndex,
                    totolPages: AppBanner.appBannerList.length,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Featured Books Section
            Row(
              children: [
                Icon(Icons.star, color: AppPalette.gradient1, size: 26),
                const SizedBox(width: 8),
                const Text(
                  'Sách nổi bật',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.gradient1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Document Categories Section
            Consumer<DocumentProvider>(
              builder: (context, p, _) {
                if (p.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (p.error != null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text(p.error!)),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TypeSection(
                      title: 'Sách',
                      items: p.books,
                      onViewAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BookPage()),
                        );
                      },
                    ),
                    TypeSection(
                      title: 'Tạp chí',
                      items: p.magazines,
                      onViewAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MagazinePage(),
                          ),
                        );
                      },
                    ),
                    TypeSection(
                      title: 'Báo',
                      items: p.newspapers,
                      onViewAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NewspaperPage(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
