import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:book_tech/features/auth/presentations/bloc/auth_bloc.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_event.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_state.dart';
import 'package:book_tech/features/auth/presentations/bloc/profile_bloc.dart';
import 'package:book_tech/features/auth/presentations/pages/sign_in.dart';
import 'package:book_tech/features/auth/presentations/pages/edit_profile_page.dart';
import 'package:book_tech/features/auth/domain/entities/profile_usecase.dart';
import 'package:book_tech/features/auth/data/repositories/profile_repository_impl.dart';
import 'package:book_tech/features/auth/data/datasources/profile_remote_datasource.dart';
import 'package:book_tech/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:book_tech/features/auth/data/datasources/local_storage_data_source.dart';
import 'package:book_tech/features/auth/data/datasources/authentication_remote_data_source.dart';
import 'package:book_tech/features/auth/presentations/pages/borrow_history_page.dart';
import 'package:book_tech/features/auth/presentations/pages/profile_detail_page.dart';
import 'package:book_tech/features/auth/presentations/pages/membership_selection_page.dart';
import 'package:book_tech/core/ui/notification_service.dart';
import 'package:book_tech/features/auth/presentations/pages/notifications_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ProfileBloc _profileBloc;

  @override
  void initState() {
    super.initState();
    _profileBloc = ProfileBloc(
      authBloc: context.read<AuthBloc>(),
      authRepository: AuthenticationRepositoryImpl(
        remoteDataSource: AuthenticationRemoteDataSourceImpl(),
        localStorageDataSource: LocalStorageDataSourceImpl(),
      ),
      getProfileUseCase: GetProfileUseCase(
        ProfileRepositoryImpl(
          ProfileRemoteDataSourceImpl(
            client: http.Client(),
            baseUrl: 'https://kltn-2025-ehsx.onrender.com/api',
          ),
        ),
      ),
      updateProfileUseCase: UpdateProfileUseCase(
        ProfileRepositoryImpl(
          ProfileRemoteDataSourceImpl(
            client: http.Client(),
            baseUrl: 'https://kltn-2025-ehsx.onrender.com/api',
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _profileBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _profileBloc,
      child: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            NotificationService.showError(
              context,
              message: 'Lỗi: ${state.message}',
            );
          }
        },
        child: _ProfilePageContent(),
      ),
    );
  }
}

class _ProfilePageContent extends StatefulWidget {
  @override
  State<_ProfilePageContent> createState() => _ProfilePageContentState();
}

class _ProfilePageContentState extends State<_ProfilePageContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // Màu sắc đồng nhất với cart_page và my_books_page
  static const Color _primaryColor = Color(0xFFFF6B35);
  static const Color _backgroundColor = Color(0xFFF8F9FA);
  static const Color _textColor = Color(0xFF1A202C);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => current is AuthUnauthenticated,
      listener: (context, state) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SignInPage()),
          (route) => false,
        );
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is AuthAuthenticated &&
              authState.account.accessToken?.isNotEmpty == true) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.read<ProfileBloc>().state is ProfileInitial) {
                context.read<ProfileBloc>().add(ProfileLoadRequested());
              }
            });
          }
          return Scaffold(
            backgroundColor: _backgroundColor,
            appBar: AppBar(
              title: const Text(
                'Tài khoản',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: _textColor,
                  letterSpacing: -0.5,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              centerTitle: true,
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 4, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          color: _textColor,
                          size: 20,
                        ),
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    tooltip: 'Thông báo',
                    onPressed: _openNotifications,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: _textColor,
                      size: 20,
                    ),
                    tooltip: 'Cài đặt',
                    onPressed: _openSettings,
                  ),
                ),
              ],
            ),
            // Thay thế dòng 137-149
            body: SafeArea(
              child: SingleChildScrollView(
                // Thêm SingleChildScrollView
                child: Column(
                  children: [
                    // Profile Header
                    _buildProfileHeader(),
                    const SizedBox(height: 16),
                    // Menu Items
                    _buildMenuItems(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 360;
        final margin = isSmallScreen ? 12.0 : 16.0;
        final padding = isSmallScreen ? 16.0 : 24.0;
        
        return Container(
          margin: EdgeInsets.fromLTRB(margin, margin, margin, 0),
          padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            );
          }

          if (state is ProfileError) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: _primaryColor,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Lỗi tải thông tin',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    final authState = context.read<AuthBloc>().state;
                    if (authState is AuthAuthenticated &&
                        (authState.account.accessToken?.isNotEmpty ?? false)) {
                      context.read<ProfileBloc>().add(ProfileLoadRequested());
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text(
                    'Thử lại',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    elevation: 4,
                    shadowColor: _primaryColor.withOpacity(0.3),
                  ),
                ),
              ],
            );
          }

          // Get user info
          final authState = context.read<AuthBloc>().state;
          String userName = 'Người dùng';
          String accountId = '0';

          if (authState is AuthAuthenticated) {
            accountId = authState.account.accountId.toString();
            userName = authState.account.fullName ?? userName;
          }
          if (state is ProfileLoaded) {
            userName = state.profile.fullName?.isNotEmpty == true
                ? state.profile.fullName!
                : (state.profile.phoneNumber?.isNotEmpty == true
                      ? 'User ${state.profile.phoneNumber} $accountId'
                      : 'Người dùng');
          } else if (state is ProfileUpdated) {
            userName = state.profile.fullName?.isNotEmpty == true
                ? state.profile.fullName!
                : (state.profile.phoneNumber?.isNotEmpty == true
                      ? 'User ${state.profile.phoneNumber} $accountId'
                      : 'Người dùng');
          }
          // Xác định ID hiển thị từ profile (nếu có) hoặc fallback theo auth
          final String displayId = (state is ProfileLoaded)
              ? (state.profile.accountId.toString())
              : (state is ProfileUpdated)
              ? (state.profile.accountId.toString())
              : accountId;
          // Navigate to profile detail page
          return InkWell(
            onTap: () {
              if (state is ProfileLoaded) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileDetailPage(profile: state.profile),
                  ),
                );
              } else if (state is ProfileUpdated) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileDetailPage(profile: state.profile),
                  ),
                );
              }
            },
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textColor,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF2F7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.badge_rounded,
                              size: 12,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'ID: $displayId',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Xem hồ sơ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: _primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: _primaryColor,
                          ),
                        ],
                      ),
                      // Hiển thị trạng thái thành viên hoặc nút nâng cấp
                      const SizedBox(height: 6),
                      _buildMembershipStatus(state),

                      // Text(
                      //   userEmail,
                      //   style: TextStyle(
                      //     fontSize: 14,
                      //     color: Colors.grey.shade600,
                      //   ),
                      //   maxLines: 1,
                      //   overflow: TextOverflow.ellipsis, // Đã có
                      // ),
                      // Text(
                      //   userPhoneNumber,
                      //   style: TextStyle(
                      //     fontSize: 14,
                      //     color: Colors.grey.shade600,
                      //   ),
                      //   maxLines: 1,
                      //   overflow: TextOverflow.ellipsis, // Đã có
                      // ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        // decoration: BoxDecoration(
                        //   color: AppPalette.gradient1.withOpacity(0.1),
                        //   borderRadius: BorderRadius.circular(12),
                        // ),
                        // child: Text(
                        //   'Độc giả',
                        //   style: TextStyle(
                        //     fontSize: 12,
                        //     color: AppPalette.gradient1,
                        //     fontWeight: FontWeight.w500,
                        //   ),
                        // ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
        );
      },
    );
  }

  Widget _buildMenuItems() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          // Thêm SingleChildScrollView
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuItem(
                icon: Icons.edit_rounded,
                title: 'Chỉnh sửa thông tin',
                isFirst: true,
                onTap: _navigateToEditProfile,
              ),
              _buildMenuItem(
                icon: Icons.history_rounded,
                title: 'Lịch sử mượn sách',
                isFirst: true,
                onTap: _navigateToBorrowHistory,
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.notifications_outlined,
                title: 'Thông báo',
                onTap: () {},
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.security_rounded,
                title: 'Bảo mật',
                onTap: () {},
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.help_outline_rounded,
                title: 'Trợ giúp',
                onTap: () {},
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.info_outline_rounded,
                title: 'Về ứng dụng',
                isLast: true,
                onTap: () {},
              ),
              const SizedBox(height: 20),
              // Logout button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.withOpacity(0.08),
                        Colors.red.withOpacity(0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: _buildMenuItem(
                    icon: Icons.logout_rounded,
                    title: 'Đăng xuất',
                    textColor: const Color(0xFFE53E3E),
                    isFirst: true,
                    isLast: true,
                    onTap: _showLogoutDialog,
                  ),
                ),
              ),
              const SizedBox(height: 16), // Thêm padding bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final itemColor = textColor ?? _primaryColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(24) : Radius.zero,
          bottom: isLast ? const Radius.circular(24) : Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: textColor == null
                      ? LinearGradient(
                          colors: [
                            itemColor.withOpacity(0.15),
                            itemColor.withOpacity(0.08),
                          ],
                        )
                      : null,
                  color: textColor != null ? itemColor.withOpacity(0.1) : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: itemColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor ?? _textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: textColor ?? Colors.grey[400],
                size: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 80),
      child: Divider(height: 1, thickness: 0.5, color: Colors.grey[200]),
    );
  }

  void _navigateToEditProfile() {
    final state = context.read<ProfileBloc>().state;
    if (state is ProfileLoaded) {
      final profileBloc = context.read<ProfileBloc>();
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: profileBloc,
                child: EditProfilePage(profile: state.profile),
              ),
            ),
          )
          .then((updatedProfile) {
            if (updatedProfile != null) {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated &&
                  (authState.account.accessToken?.isNotEmpty ?? false)) {
                context.read<ProfileBloc>().add(ProfileLoadRequested());
              }
            }
          });
    } else {
      NotificationService.showInfo(
        context,
        message: 'Vui lòng đợi tải thông tin profile',
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE53E3E).withOpacity(0.15),
                        const Color(0xFFE53E3E).withOpacity(0.08),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFE53E3E),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Đăng xuất',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Bạn có chắc chắn muốn đăng xuất?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          'Hủy',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _performLogout(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53E3E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Đăng xuất',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _performLogout(BuildContext context) {
    Navigator.of(context).pop();

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                  strokeWidth: 2.5,
                ),
                const SizedBox(height: 20),
                Text(
                  'Đang đăng xuất...',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    context.read<AuthBloc>().add(AuthLogoutRequested());

    Future.delayed(const Duration(milliseconds: 800), () {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      NotificationService.showSuccess(
        context,
        message: 'Đăng xuất thành công!',
      );
    });
  }

  void _navigateToBorrowHistory() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BorrowHistoryPage()));
  }

  void _openNotifications() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
  }

  void _openSettings() {
    NotificationService.showInfo(
      context,
      message: 'Tính năng Cài đặt đang phát triển',
    );
  }

  Widget _buildMembershipStatus(ProfileState state) {
    final profile = state is ProfileLoaded
        ? state.profile
        : (state is ProfileUpdated ? state.profile : null);

    if (profile == null) return const SizedBox.shrink();

    final memberCard = profile.memberCard;
    final cardType = memberCard?.cardType;
    final bool hasFullMembership =
        memberCard != null && cardType != null && cardType.canBorrowHome;
    final bool shouldPromptUpgrade =
        memberCard == null ||
        (cardType != null && cardType.maxBorrowLimit == 0);

    if (hasFullMembership && !shouldPromptUpgrade) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.card_membership, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                cardType.typeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final label = memberCard == null
        ? 'Chưa có thẻ thành viên'
        : 'Thẻ miễn phí';
    final subtitle = memberCard == null
        ? 'Nhấn để đăng ký và mượn sách'
        : 'Nâng cấp để mượn sách mang về';

    return InkWell(
      onTap: _navigateToUpgradeMembership,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryColor, _primaryColor.withOpacity(0.85)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.upgrade, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToUpgradeMembership() {
    final profileState = context.read<ProfileBloc>().state;
    final profile = profileState is ProfileLoaded
        ? profileState.profile
        : (profileState is ProfileUpdated ? profileState.profile : null);

    if (profile == null) {
      NotificationService.showInfo(
        context,
        message: 'Vui lòng chờ tải thông tin hồ sơ trước khi nâng cấp.',
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    final email =
        profile.email ??
        (authState is AuthAuthenticated ? authState.account.email : null) ??
        'user@example.com';

    Navigator.of(context)
        .push<bool>(
          MaterialPageRoute(
            builder: (_) => MembershipSelectionPage(
              readerId: profile.readerId,
              accountId: profile.accountId,
              email: email,
              isFromRegistration: false,
              onMembershipUpdated: () {
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthAuthenticated &&
                    (authState.account.accessToken?.isNotEmpty ?? false)) {
                  context.read<ProfileBloc>().add(ProfileLoadRequested());
                }
              },
            ),
          ),
        )
        .then((success) {
          if (success == true) {
            final authState = context.read<AuthBloc>().state;
            if (authState is AuthAuthenticated &&
                (authState.account.accessToken?.isNotEmpty ?? false)) {
              context.read<ProfileBloc>().add(ProfileLoadRequested());
            }
          }
        });
  }
}
