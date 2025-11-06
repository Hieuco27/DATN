import 'package:book_tech/features/auth/domain/repositories/document_repository.dart';
import 'package:book_tech/features/auth/presentations/pages/ebook_reader_page.dart';
import 'package:book_tech/features/auth/presentations/pages/genres_list_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'package:book_tech/features/auth/presentations/providers/cart_provider.dart';
import 'package:book_tech/features/auth/presentations/providers/wishlist_provider.dart';
import 'package:book_tech/features/auth/presentations/providers/reading_provider.dart';
import 'package:book_tech/features/auth/presentations/pages/cart_page.dart';
import 'package:book_tech/core/navigation/detail_route.dart';
import 'package:animations/animations.dart';
import 'package:cosmos_epub/cosmos_epub.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Khởi tạo CosmosEpub
  final cosmosInitialized = await CosmosEpub.initialize();
  if (!cosmosInitialized) {
    print('⚠️ Failed to initialize CosmosEpub');
  }

  // Khởi tạo các dependencies
  final remoteDataSource = AuthenticationRemoteDataSourceImpl();
  final localStorageDataSource = LocalStorageDataSourceImpl();
  final authRepository = AuthenticationRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localStorageDataSource: localStorageDataSource,
  );

  runApp(MyApp(authRepository: authRepository));
}

class MyApp extends StatelessWidget {
  final AuthenticationRepositoryImpl authRepository;

  const MyApp({super.key, required this.authRepository});

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
        // SearchProvider có thể đọc DocumentRepositoryImpl
        ChangeNotifierProvider(
          create: (context) => SearchProvider(
            Provider.of<DocumentRepository>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider<DocumentProvider>(
          create: (ctx) => DocumentProvider(ctx.read<DocumentRepositoryImpl>()),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => ReadingProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Book Tech',
        theme: AppTheme.darkThemeMode,
        home: const SplashPage(),
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
        print('🔄 Auth state changed: ${state.runtimeType}');

        if (state is AuthAuthenticated) {
          // Navigate to main home page when authenticated
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          print('🔄 Building AuthWrapper with state: ${state.runtimeType}');

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
