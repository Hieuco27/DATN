// lib/features/auth/presentations/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:book_tech/features/auth/presentations/pages/main_home_page.dart';
import 'package:book_tech/features/auth/presentations/pages/my_books_page.dart';
import 'package:book_tech/features/auth/presentations/pages/profile_page.dart';
import 'package:book_tech/features/auth/presentations/pages/genres_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const MainHomePage(),
    const GenresListPage(),
    const MyBooksPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        color: Colors.white, // Ensure full-width white background
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: GNav(
                gap: 8,
                rippleColor: const Color(0x22FF1744),
                hoverColor: const Color(0x11FF1744),
                tabBackgroundColor: const Color(0x1AFF1744),
                color: Colors.black54,
                activeColor: const Color.fromARGB(234, 248, 155, 16),
                iconSize: 22,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                selectedIndex: _currentIndex,
                onTabChange: (index) {
                  setState(() => _currentIndex = index);
                },
                tabs: const [
                  GButton(icon: Icons.home_rounded, text: 'Trang chủ'),
                  GButton(icon: Icons.grid_view_rounded, text: 'Thể loại'),
                  GButton(icon: Icons.library_books_rounded, text: 'Thư viện'),
                  GButton(icon: Icons.person_rounded, text: 'Tôi'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
