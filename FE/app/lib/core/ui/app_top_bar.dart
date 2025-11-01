import 'package:flutter/material.dart';

enum AppTopBarLeading {
  back,
  menu,
  none,
}

class AppTopBarAction {
  final Widget icon;
  final VoidCallback onTap;
  final String? tooltip;

  const AppTopBarAction({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  factory AppTopBarAction.search({required VoidCallback onTap}) {
    return AppTopBarAction(
      icon: const Icon(Icons.search, color: Colors.red),
      onTap: onTap,
      tooltip: 'Tìm kiếm',
    );
  }

  factory AppTopBarAction.more({
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return AppTopBarAction(
      icon: const Icon(Icons.more_vert, color: Colors.black),
      onTap: onTap,
      tooltip: tooltip ?? 'Thêm',
    );
  }

  factory AppTopBarAction.custom({
    required Widget icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return AppTopBarAction(
      icon: icon,
      onTap: onTap,
      tooltip: tooltip,
    );
  }
}

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final AppTopBarLeading leadingType;
  final VoidCallback? onLeadingTap;
  final List<AppTopBarAction>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool centerTitle;

  const AppTopBar({
    super.key,
    required this.title,
    this.leadingType = AppTopBarLeading.back,
    this.onLeadingTap,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: foregroundColor ?? Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: backgroundColor ?? Colors.white,
      elevation: 0,
      centerTitle: centerTitle,
      leading: _buildLeading(context),
      leadingWidth: leadingType == AppTopBarLeading.none ? 0 : null,
      actions: _buildActions(),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    switch (leadingType) {
      case AppTopBarLeading.back:
        return IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: foregroundColor ?? Colors.black,
          ),
          onPressed: onLeadingTap ?? () => Navigator.of(context).pop(),
        );
      case AppTopBarLeading.menu:
        return IconButton(
          icon: Icon(
            Icons.menu,
            color: foregroundColor ?? Colors.black,
          ),
          onPressed: onLeadingTap,
        );
      case AppTopBarLeading.none:
        return null;
    }
  }

  List<Widget>? _buildActions() {
    if (actions == null || actions!.isEmpty) return null;

    return actions!.map((action) {
      if (action.tooltip != null) {
        return Tooltip(
          message: action.tooltip!,
          child: IconButton(
            icon: action.icon,
            onPressed: action.onTap,
          ),
        );
      }
      return IconButton(
        icon: action.icon,
        onPressed: action.onTap,
      );
    }).toList();
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

