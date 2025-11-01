import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:book_tech/features/auth/presentations/providers/document_provider.dart';
import 'package:book_tech/features/auth/presentations/pages/genres_book_page.dart';
import 'package:book_tech/features/auth/data/models/genre_model.dart';
import 'package:book_tech/features/auth/presentations/pages/search_page.dart';

class GenresListPage extends StatefulWidget {
  const GenresListPage({super.key});
  @override
  State<GenresListPage> createState() => _GenresListPageState();
}

class _GenresListPageState extends State<GenresListPage> {
  final Map<int, String> _imageByGenreId = const {
    120703: 'assets/image/genres/technology.png', // Công nghệ
    120716: 'assets/image/genres/travel.png', // Du lịch
    120717: 'assets/image/genres/amthuc.png', // Ẩm thực
    120719: 'assets/image/genres/music.png', // Âm nhạc
    120722: 'assets/image/genres/chinhtri.png', // Chính trị
    120724: 'assets/image/genres/cotich.png',
    120701: 'assets/image/genres/tieuthuyet.png',
    120702: 'assets/image/genres/kinhte.png',
    120704: 'assets/image/genres/khoahoc.png',
    120705: 'assets/image/genres/history.png',
    120706: 'assets/image/genres/dialy.png',
    120707: 'assets/image/genres/tamly.png',
    120708: 'assets/image/genres/kynangsong.png',
    120709: 'assets/image/genres/thieunhi.png',
    120710: 'assets/image/genres/vanhoc.png',
    120711: 'assets/image/genres/tongiao.png',
    120712: 'assets/image/genres/triethoc.png',
    120713: 'assets/image/genres/yhoc.png',
    120714: 'assets/image/genres/nghethuat.png',
    120715: 'assets/image/genres/kientruc.png',
    120718: 'assets/image/genres/ngoaingu.png',
    120720: 'assets/image/genres/thethao.png',
    120721: 'assets/image/genres/phapluat.png',
    120723: 'assets/image/genres/moitruong.png',
    120725: 'assets/image/genres/tho.png',
    120726: 'assets/image/genres/tanvan.png',
    120727: 'assets/image/genres/khoinghiep.png',
    120728: 'assets/image/genres/phattrienbanthan.png',
    120729: 'assets/image/genres/quantri.png',
    120730: 'assets/image/genres/marketing.png',
    120731: 'assets/image/genres/test.png',
  };
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

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.70,
            ),
            itemCount: genres.length,
            itemBuilder: (context, index) {
              final g = genres[index];
              final name = g.name.toUpperCase();
              final img = _imageByGenreId[g.genreId];

              return _GenreTile(
                title: name,
                imageUrl: img,
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
      ),
    );
  }
}

class _GenreTile extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final VoidCallback onTap;

  const _GenreTile({required this.title, required this.onTap, this.imageUrl});

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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
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
