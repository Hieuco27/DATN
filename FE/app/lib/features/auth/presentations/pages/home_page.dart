// lib/features/auth/presentations/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:book_tech/core/theme/app_palette.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:book_tech/features/auth/presentations/pages/main_home_page.dart';
import 'package:book_tech/features/auth/presentations/pages/search_page.dart';
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
      bottomNavigationBar: ConvexAppBar(
        backgroundColor: Colors.white, // Nền trắng
        color: Colors.grey, // Màu xám cho tab không active
        activeColor: Colors.red, // Màu đỏ cho tab active
        style: TabStyle.react,
        curveSize: 80,
        items: const [
          TabItem(icon: Icons.home, title: 'Trang chủ'),
          TabItem(
            icon: Icons.grid_view,
            title: 'Thể loại',
          ), // Thay đổi icon và title
          TabItem(
            icon: Icons.library_books,
            title: 'Thư viện',
          ), // Thay đổi icon và title
          TabItem(
            icon: Icons.person,
            title: 'Tài khoản',
          ), // Thay đổi icon và title
        ],
        initialActiveIndex: 0,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
