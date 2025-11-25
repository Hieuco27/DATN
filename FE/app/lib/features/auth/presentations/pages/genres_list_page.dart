import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:book_tech/features/auth/presentations/providers/document_provider.dart';
import 'package:book_tech/features/auth/presentations/pages/genres_book_page.dart';
import 'package:book_tech/features/auth/data/models/genre_model.dart';
import 'package:book_tech/features/auth/presentations/pages/search_page.dart';
import 'package:book_tech/core/widgets/gradient_background.dart';

class GenresListPage extends StatefulWidget {
  const GenresListPage({super.key});
  @override
  State<GenresListPage> createState() => _GenresListPageState();
}

class _GenresListPageState extends State<GenresListPage> {
  // Pool ảnh dùng chung cho mọi thể loại. Ảnh sẽ được chọn "ngẫu nhiên có định
  // danh" dựa trên genreId để đảm bảo ổn định giữa các lần render và không phụ
  // thuộc dữ liệu id cố định từ backend.
  final List<String> _genreImages = const [
    'assets/image/genres/technology.png',
    'assets/image/genres/travel.png',
    'assets/image/genres/amthuc.png',
    'assets/image/genres/music.png',
    'assets/image/genres/chinhtri.png',
    'assets/image/genres/cotich.png',
    'assets/image/genres/tieuthuyet.png',
    'assets/image/genres/kinhte.png',
    'assets/image/genres/khoahoc.png',
    'assets/image/genres/history.png',
    'assets/image/genres/dialy.png',
    'assets/image/genres/tamly.png',
    'assets/image/genres/kynangsong.png',
    'assets/image/genres/thieunhi.png',
    'assets/image/genres/vanhoc.png',
    'assets/image/genres/tongiao.png',
    'assets/image/genres/triethoc.png',
    'assets/image/genres/yhoc.png',
    'assets/image/genres/nghethuat.png',
    'assets/image/genres/kientruc.png',
    'assets/image/genres/ngoaingu.png',
    'assets/image/genres/thethao.png',
    'assets/image/genres/phapluat.png',
    'assets/image/genres/moitruong.png',
    'assets/image/genres/tho.png',
    'assets/image/genres/tanvan.png',
    'assets/image/genres/khoinghiep.png',
    'assets/image/genres/phattrienbanthan.png',
    'assets/image/genres/quantri.png',
    'assets/image/genres/marketing.png',
    'assets/image/genres/test.png',
  ];

  String? _pickImageForGenre(GenreModel genre) {
    if (_genreImages.isEmpty) return null;
    final int positiveId = genre.genreId >= 0 ? genre.genreId : -genre.genreId;
    final int index = positiveId % _genreImages.length;
    return _genreImages[index];
  }

  @override
  void initState() {
    super.initState();
    // Đảm bảo có dữ liệu thể loại
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      if (docProvider.genres.isEmpty) {
        docProvider.loadGenres(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Thể loại',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.red),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchPage()),
                );
              },
              tooltip: 'Tìm kiếm',
            ),
          ),
        ],
      ),
      body: Consumer<DocumentProvider>(
        child: const AppGradientBackground(),
        builder: (context, provider, _) {
          if (provider.isLoadingGenres) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<GenreModel> genres = provider.genres;
          if (genres.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có thể loại',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isSmallScreen = screenWidth < 360;
              final isMediumScreen = screenWidth < 380;
              
              // Responsive values
              final padding = isSmallScreen ? 8.0 : 12.0;
              final spacing = isSmallScreen ? 8.0 : 12.0;
              final crossAxisCount = isSmallScreen ? 2 : 3;
              final childAspectRatio = isSmallScreen ? 0.75 : (isMediumScreen ? 0.72 : 0.70);
              
              return GridView.builder(
                padding: EdgeInsets.all(padding),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: genres.length,
                itemBuilder: (context, index) {
                  final g = genres[index];
                  final name = g.name.toUpperCase();
                  final img = _pickImageForGenre(g);

                  return _GenreTile(
                    title: name,
                    imageUrl: img,
                    isSmallScreen: isSmallScreen,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              GenreBooksPage(genreName: g.name, genreId: g.genreId),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _GenreTile extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final VoidCallback onTap;
  final bool isSmallScreen;

  const _GenreTile({
    required this.title,
    required this.onTap,
    this.imageUrl,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(10);

    Widget background;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      background = ClipRRect(
        borderRadius: borderRadius,
        child: Image.asset(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _gradientBG(),
        ),
      );
    } else {
      background = _gradientBG();
    }

    return InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          Positioned.fill(child: background),
          // Khung chữ giữa như ảnh mẫu
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 10,
                vertical: isSmallScreen ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Text(
                title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: isSmallScreen ? 11.0 : 12.5,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientBG() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFFCFD9DF), Color(0xFFE2EBF0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}
