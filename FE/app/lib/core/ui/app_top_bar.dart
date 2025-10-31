import 'package:flutter/material.dart';

enum AppTopBarLeading { none, back, menu }

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final AppTopBarLeading leadingType;
  final VoidCallback? onLeadingTap;
  final List<Widget>? actions;
  final List<Color> gradientColors;

  const AppTopBar({
    super.key,
    required this.title,
    this.leadingType = AppTopBarLeading.back,
    this.onLeadingTap,
    this.actions,
    this.gradientColors = const [Color(0xFFFF1744), Color(0xFFFF5252)],
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      shadowColor: Colors.transparent,
      toolbarHeight: preferredSize.height,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
      ),
      leading: _buildLeading(context),
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      actions: actions,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    switch (leadingType) {
      case AppTopBarLeading.none:
        return null;
      case AppTopBarLeading.menu:
        return IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 24),
          onPressed: onLeadingTap,
        );
      case AppTopBarLeading.back:
        return IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: onLeadingTap ?? () => Navigator.of(context).maybePop(),
        );
    }
  }
}

class AppTopBarAction {
  static Widget search({required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.search, color: Colors.white, size: 20),
              SizedBox(width: 6),
              Text(
                'Tìm kiếm',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
