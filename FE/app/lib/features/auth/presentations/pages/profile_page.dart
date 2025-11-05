import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:book_tech/core/theme/app_palette.dart';
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
import 'package:book_tech/core/ui/notification_service.dart';

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

class _ProfilePageContentState extends State<_ProfilePageContent> {
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
            backgroundColor: Color(0xFFF8F9FA), // màu xám nhạt

            appBar: AppBar(
              title: const Text(
                'Tài khoản',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0.5,
              automaticallyImplyLeading: false,
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.black87,
                  ),
                  tooltip: 'Thông báo',
                  onPressed: _openNotifications,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.black87,
                  ),
                  tooltip: 'Cài đặt',
                  onPressed: _openSettings,
                ),
                const SizedBox(width: 4),
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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppPalette.gradient1),
              ),
            );
          }

          if (state is ProfileError) {
            return Column(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Colors.orange.shade400,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  'Lỗi tải thông tin',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    final authState = context.read<AuthBloc>().state;
                    if (authState is AuthAuthenticated &&
                        (authState.account.accessToken?.isNotEmpty ?? false)) {
                      context.read<ProfileBloc>().add(ProfileLoadRequested());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.gradient1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    'Thử lại',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            );
          }

          // Get user info
          final authState = context.read<AuthBloc>().state;
          String userName = 'Người dùng';
          String userEmail = 'user@example.com';
          String userPhoneNumber = '0000000000';
          String accountId = '0';

          if (authState is AuthAuthenticated) {
            accountId = authState.account.accountId?.toString() ?? '0';
            userEmail = authState.account.email;
            userName = authState.account.fullName ?? userName;
            userPhoneNumber = authState.account.phoneNumber;
          }
          if (state is ProfileLoaded) {
            userName = state.profile.fullName?.isNotEmpty == true
                ? state.profile.fullName!
                : (state.profile.phoneNumber?.isNotEmpty == true
                      ? 'User ${state.profile.phoneNumber} ${accountId}'
                      : 'Người dùng');
          } else if (state is ProfileUpdated) {
            userName = state.profile.fullName?.isNotEmpty == true
                ? state.profile.fullName!
                : (state.profile.phoneNumber?.isNotEmpty == true
                      ? 'User ${state.profile.phoneNumber} ${accountId}'
                      : 'Người dùng');
          }
          // Xác định ID hiển thị từ profile (nếu có) hoặc fallback theo auth
          final String displayId = (state is ProfileLoaded)
              ? (state.profile.accountId?.toString() ?? accountId)
              : (state is ProfileUpdated)
              ? (state.profile.accountId?.toString() ?? accountId)
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
                    gradient: const LinearGradient(
                      colors: [AppPalette.gradient1, AppPalette.gradient2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  // Đảm bảo có Expanded
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis, // Đã có
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: $displayId',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'Xem hồ sơ >',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color.fromARGB(255, 120, 120, 120),
                          fontWeight: FontWeight.w600,
                        ),
                      ),

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
  }

  Widget _buildMenuItems() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
              const SizedBox(height: 24),
              // Logout button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.1)),
                  ),
                  child: _buildMenuItem(
                    icon: Icons.logout_rounded,
                    title: 'Đăng xuất',
                    textColor: Colors.red,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(16) : Radius.zero,
          bottom: isLast ? const Radius.circular(16) : Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (textColor ?? AppPalette.gradient1).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: textColor ?? AppPalette.gradient1,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor ?? Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: textColor ?? Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 72),
      child: Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
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
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.red.shade500,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Đăng xuất',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bạn có chắc chắn muốn đăng xuất?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
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
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Đăng xuất',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
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
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppPalette.gradient1,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Đang đăng xuất...',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
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
    NotificationService.showInfo(
      context,
      message: 'Tính năng Thông báo đang phát triển',
    );
  }

  void _openSettings() {
    NotificationService.showInfo(
      context,
      message: 'Tính năng Cài đặt đang phát triển',
    );
  }
}
