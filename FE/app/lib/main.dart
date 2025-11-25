import 'package:book_tech/features/auth/domain/repositories/document_repository.dart';
import 'package:book_tech/features/auth/presentations/pages/ebook_reader_page.dart';
import 'package:book_tech/features/auth/presentations/pages/genres_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:book_tech/features/auth/presentations/pages/sign_in.dart';
import 'package:book_tech/core/theme/theme.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_bloc.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_event.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_state.dart';
import 'package:book_tech/features/auth/data/datasources/local_storage_data_source.dart';
import 'package:book_tech/features/auth/data/datasources/authentication_remote_data_source.dart';
import 'package:book_tech/features/auth/data/repositories/auth_repository_impl.dart';
//
import 'package:provider/provider.dart';
import 'package:book_tech/features/auth/data/datasources/document_remote_data_source.dart';
import 'package:book_tech/features/auth/data/repositories/document_repository_impl.dart';
import 'package:book_tech/features/auth/presentations/providers/document_provider.dart';
import 'package:book_tech/features/auth/presentations/providers/search_provider.dart';
import 'package:book_tech/features/auth/presentations/pages/home_page.dart';
import 'package:book_tech/features/auth/presentations/pages/document_detail_page.dart';
import 'package:book_tech/features/auth/presentations/pages/search_page.dart';
import 'package:book_tech/features/auth/presentations/pages/splash_page.dart';
// ✅ BLoC imports (migration complete for Cart, Wishlist, Reading)
import 'package:book_tech/features/auth/presentations/bloc/cart_bloc.dart';
import 'package:book_tech/features/auth/presentations/bloc/wishlist_bloc.dart';
import 'package:book_tech/features/auth/presentations/bloc/reading_bloc.dart';
import 'package:book_tech/features/auth/presentations/pages/cart_page.dart';
import 'package:book_tech/core/navigation/detail_route.dart';
import 'package:animations/animations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global RouteObserver để track navigation trong app
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final hasLoggedInBefore = prefs.getBool('has_logged_in_before') ?? false;

  final remoteDataSource = AuthenticationRemoteDataSourceImpl();
  final localStorageDataSource = LocalStorageDataSourceImpl();
  
  await localStorageDataSource.initialize();
  
  final authRepository = AuthenticationRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localStorageDataSource: localStorageDataSource,
  );
  
  runApp(
    MyApp(authRepository: authRepository, showSplashOnStart: !hasLoggedInBefore),
  );
}

class MyApp extends StatelessWidget {
  final AuthenticationRepositoryImpl authRepository;
  final bool showSplashOnStart;

  const MyApp({
    super.key,
    required this.authRepository,
    required this.showSplashOnStart,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              AuthBloc(authRepository: authRepository)
                ..add(const AuthCheckLoginStatus()),
        ),
        Provider<DocumentRemoteDataSource>(
          create: (_) => DocumentRemoteDataSourceImpl(),
        ),
        Provider<DocumentRepositoryImpl>(
          create: (context) => DocumentRepositoryImpl(
            remoteDataSource: context.read<DocumentRemoteDataSource>(),
          ),
        ),
        Provider<DocumentRepository>(
          create: (context) => context.read<DocumentRepositoryImpl>(),
        ),
        // ✅ Migration to BLoC-only: Replace all Providers with BLoCs
        // SearchProvider → SearchBloc (TODO: implement SearchBloc)
        ChangeNotifierProvider(
          create: (context) => SearchProvider(
            Provider.of<DocumentRepository>(context, listen: false),
          ),
        ),
        // DocumentProvider → DocumentBloc (TODO: implement DocumentBloc)
        ChangeNotifierProvider<DocumentProvider>(
          create: (ctx) => DocumentProvider(ctx.read<DocumentRepositoryImpl>()),
        ),
        
        // ✅ BLoC implementations (simple features done)
        BlocProvider(
          create: (_) => CartBloc(),
        ),
        BlocProvider(
          create: (_) => WishlistBloc(),
        ),
        BlocProvider(
          create: (_) => ReadingBloc(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Book Tech',
        theme: AppTheme.darkThemeMode,
        navigatorObservers: [
          routeObserver, // ✅ Global observer cho RouteAware
        ],
        home: showSplashOnStart ? const SplashPage() : const AuthWrapper(),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/document-detail':
              {
                final args = settings.arguments;
                if (args is int) {
                  return buildSharedAxisDetailRoute(
                    page: DocumentDetailPage(documentId: args),
                    type: SharedAxisTransitionType.horizontal,
                  );
                }
                throw Exception('Document ID is required');
              }
            case '/search':
              return buildSharedAxisDetailRoute(
                page: const SearchPage(),
                type: SharedAxisTransitionType.scaled,
              );
            case '/ebook-reader':
              {
                final args = settings.arguments;
                if (args is Map<String, dynamic>) {
                  return buildSharedAxisDetailRoute(
                    page: EbookReaderPage(
                      document: args['document'],
                      ebookUrl: args['ebookUrl'],
                    ),
                    type: SharedAxisTransitionType.vertical,
                  );
                }
                throw Exception('Document and ebookUrl are required');
              }
            case '/cart':
              return buildSharedAxisDetailRoute(
                page: const CartPage(),
                type: SharedAxisTransitionType.scaled,
              );
            case '/genre':
              return buildSharedAxisDetailRoute(
                page: const GenresListPage(),
                type: SharedAxisTransitionType.scaled,
              );
          }
          return null;
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Navigate to main home page when authenticated
          // Use addPostFrameCallback to avoid Navigator lock during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            }
          });
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Chỉ trả về SignInPage nếu chưa authenticated
          if (state is! AuthAuthenticated) {
            return const SignInPage();
          }
          // Trả về loading trong khi chuyển trang
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
