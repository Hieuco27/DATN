// lib/features/auth/presentations/pages/main_home_page.dart
import 'dart:async';
import 'package:book_tech/features/auth/data/models/genre_model.dart';
import 'package:book_tech/features/auth/presentations/pages/genres_book_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:book_tech/core/theme/app_palette.dart';
import 'package:book_tech/features/auth/presentations/widgets/home/page_indicator.dart';
import 'package:book_tech/features/auth/presentations/widgets/home/new_navigation.dart'
    as new_navigation;
import 'package:book_tech/features/auth/presentations/widgets/document/document.dart';
import '../providers/document_provider.dart';
import '../pages/search_page.dart';
import '../widgets/document/genre_section.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/home/book_quote_box.dart';

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
  final List<GenreModel> _genres = [];
  bool _isLoadingGenres = false;
  String _accessToken = '';

  // Thêm state cho segmented control
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _bannerPageController = PageController(viewportFraction: 0.8);

    // Listen to focus changes
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });

    // Thay thế phần initState() từ dòng 54-60:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      docProvider.loadGenres(context); // Load genres trước
    });
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    // Hiện tại chỉ hiển thị snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tìm kiếm: "$query"'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color.fromARGB(255, 106, 106, 106),
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black, size: 24),
          onPressed: () {
            _showNavigationModal(context);
          },
        ),
        title: const Text(
          'Trang chủ',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.red, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Segmented Control
          Container(
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 0
                            ? Colors.red
                            : const Color.fromARGB(0, 0, 0, 0),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        'Khám phá',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedTabIndex == 0
                              ? Colors.white
                              : const Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 1
                            ? Colors.red
                            : const Color.fromARGB(0, 0, 0, 0),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        'Phổ biến',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedTabIndex == 1
                              ? Colors.white
                              : const Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 2;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 2
                            ? Colors.red
                            : const Color.fromARGB(0, 0, 0, 0),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        'Mới nhất',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedTabIndex == 2
                              ? Colors.white
                              : const Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content based on selected tab
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 16.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  // Thay thế phần Consumer<DocumentProvider> bằng:
                  Consumer<DocumentProvider>(
                    builder: (context, documentProvider, child) {
                      if (documentProvider.isLoadingGenres) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BookQuoteBox(),
                          // Hiển thị từng genre với danh sách sách
                          ...documentProvider.genres.map((genre) {
                            return GenreSectionWidget(
                              genre: genre,
                              documentProvider: documentProvider,
                            );
                          }).toList(),

                          // Nếu có nhiều hơn 2 genres, hiển thị nút "Xem thêm"
                          // if (documentProvider.genres.length > 2)
                          //   Center(
                          //     child: TextButton(
                          //       onPressed: () {
                          //         Navigator.push(
                          //           context,
                          //           MaterialPageRoute(
                          //             builder: (context) => GenreBooksPage(
                          //               genreName: 'Tất cả thể loại',
                          //               genreId: null,
                          //             ),
                          //           ),
                          //         );
                          //       },
                          //       child: const Text(
                          //         'Xem thêm thể loại',
                          //         style: TextStyle(
                          //           color: Colors.red,
                          //           fontWeight: FontWeight.w600,
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
