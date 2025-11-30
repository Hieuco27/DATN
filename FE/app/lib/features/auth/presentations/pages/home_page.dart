// lib/features/auth/presentations/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:book_tech/features/auth/presentations/pages/main_home_page.dart';
import 'package:book_tech/features/auth/presentations/pages/my_books_page.dart';
import 'package:book_tech/features/auth/presentations/pages/profile_page.dart';
import 'package:book_tech/features/auth/presentations/pages/genres_list_page.dart';
import 'package:book_tech/features/auth/presentations/pages/sign_in.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_bloc.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_state.dart';
import 'package:book_tech/features/auth/presentations/pages/cart_page.dart';

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
    // const CartPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Khi logout thành công, navigate về trang đăng nhập
        if (state is AuthUnauthenticated) {
          // Đóng loading dialog nếu đang mở (sử dụng rootNavigator)
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          
          // Navigate về trang đăng nhập và xóa toàn bộ navigation stack
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SignInPage()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: _pages[_currentIndex],
        bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isSmallScreen = screenWidth < 360;
          final isMediumScreen = screenWidth < 380;
          
          // Responsive values
          final containerPadding = isSmallScreen ? 8.0 : 12.0;
          final innerPadding = isSmallScreen ? 8.0 : 12.0;
          final gap = isSmallScreen ? 4.0 : (isMediumScreen ? 6.0 : 8.0);
          final iconSize = isSmallScreen ? 20.0 : 22.0;
          final buttonPadding = isSmallScreen 
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
              : (isMediumScreen 
                  ? const EdgeInsets.symmetric(horizontal: 10, vertical: 9)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 10));
          
          return Container(
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(containerPadding, 8, containerPadding, containerPadding),
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
                  padding: EdgeInsets.symmetric(horizontal: innerPadding, vertical: 8),
                  child: GNav(
                    gap: gap,
                    rippleColor: const Color(0x22FF1744),
                    hoverColor: const Color(0x11FF1744),
                    tabBackgroundColor: const Color(0x1AFF1744),
                    color: Colors.black54,
                    activeColor: const Color.fromARGB(234, 248, 155, 16),
                    iconSize: iconSize,
                    padding: buttonPadding,
                    selectedIndex: _currentIndex,
                    onTabChange: (index) {
                      setState(() => _currentIndex = index);
                    },
                    tabs: const [
                      GButton(icon: Icons.home_rounded, text: 'Trang chủ'),
                      GButton(icon: Icons.grid_view_rounded, text: 'Thể loại'),
                      GButton(icon: Icons.library_books_rounded, text: 'Thư viện'),
                      GButton(icon: Icons.person_rounded, text: 'Tôi'),
                      // GButton(icon: Icons.history_rounded, text: 'Giỏ sách'),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      ), // Đóng Scaffold
    ); // Đóng BlocListener
  }
}
