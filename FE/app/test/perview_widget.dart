import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

void main() {
  runApp(MySimpleApp());
}

class MySimpleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        useMaterial3: true,
      ),
      home: const _PreviewHeroPage(),
    );
  }
}

class _PreviewHeroPage extends StatefulWidget {
  const _PreviewHeroPage({Key? key}) : super(key: key);

  @override
  State<_PreviewHeroPage> createState() => _PreviewHeroPageState();
}

class _PreviewHeroPageState extends State<_PreviewHeroPage>
    with TickerProviderStateMixin {
  late final AnimationController introController;
  late final Animation<double> fadeTitle;
  late final Animation<Offset> slideTitle;
  late final Animation<double> fadeSubtitle;
  late final Animation<Offset> slideSubtitle;
  late final Animation<double> fadeCard;
  late final Animation<Offset> slideCard;
  late final Animation<double> ctaScale;

  @override
  void initState() {
    super.initState();
    introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    fadeTitle = CurvedAnimation(
      parent: introController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    slideTitle = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: introController,
            curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
          ),
        );

    fadeSubtitle = CurvedAnimation(
      parent: introController,
      curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
    );
    slideSubtitle =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
          CurvedAnimation(
            parent: introController,
            curve: const Interval(0.25, 0.65, curve: Curves.easeOutCubic),
          ),
        );

    fadeCard = CurvedAnimation(
      parent: introController,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
    );
    slideCard = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: introController,
            curve: const Interval(0.35, 0.9, curve: Curves.easeOutCubic),
          ),
        );

    ctaScale = CurvedAnimation(
      parent: introController,
      curve: const Interval(0.7, 1.0, curve: Curves.elasticOut),
    );

    // Start intro
    introController.forward();
  }

  @override
  void dispose() {
    introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
          ),
          onPressed: () {},
          tooltip: 'Back',
        ),
        title: const Text(
          'Book of the week',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.menu_rounded, color: Colors.black87),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book of the week card
                FadeTransition(
                  opacity: fadeCard,
                  child: SlideTransition(
                    position: slideCard,
                    child: _BookOfWeekCard(),
                  ),
                ),
                const SizedBox(height: 20),
                // Recommended for you
                FadeTransition(
                  opacity: fadeTitle,
                  child: SlideTransition(
                    position: slideTitle,
                    child: const Text(
                      'Recommended for you',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _RecommendedStrip(),
                const SizedBox(height: 20),
                const Text(
                  'Popular books',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _PopularList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroBookCard extends StatefulWidget {
  @override
  State<_HeroBookCard> createState() => _HeroBookCardState();
}

class _HeroBookCardState extends State<_HeroBookCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController floatController;

  @override
  void initState() {
    super.initState();
    floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Floating book illustration
          SizedBox(
            height: 160,
            child: AnimatedBuilder(
              animation: floatController,
              builder: (context, _) {
                final t = floatController.value;
                final dy = math.sin(t * 2 * math.pi) * 6;
                final rotate = math.sin(t * 2 * math.pi) * 0.03;
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: Transform.rotate(angle: rotate, child: _BookMock()),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Hơn 10.000+ đầu sách',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Từ kinh điển đến hiện đại, cập nhật mỗi tuần.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(4, (i) {
              return Container(
                width: i == 1 ? 18 : 8,
                height: 8,
                margin: EdgeInsets.only(right: i == 3 ? 0 : 8),
                decoration: BoxDecoration(
                  color: i == 1
                      ? const Color(0xFF5A67D8)
                      : const Color(0xFF5A67D8).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _BookMock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF7F9CF5), Color(0xFF5A67D8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            right: -10,
            top: -10,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -6,
            bottom: -6,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Book spine
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 14,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // Title mock
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'BOOK TECH',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Read • Learn • Grow',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookOfWeekCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF7F9CF5), Color(0xFF5A67D8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The Psychology of Money',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Timeless lessons on wealth, greed, and happiness.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        final book = mockBooks.first;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BookDetailPage(book: book),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE97777),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Shop Now',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () {
                        final book = mockBooks.first;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BookDetailPage(book: book),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Learn More'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedStrip extends StatefulWidget {
  @override
  State<_RecommendedStrip> createState() => _RecommendedStripState();
}

class _RecommendedStripState extends State<_RecommendedStrip> {
  final PageController _pageController = PageController(viewportFraction: 0.36);
  int _current = 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _RecommendedCard(index: index),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final bool active = i == (_current % 3);
            return Container(
              width: active ? 8 : 6,
              height: active ? 8 : 6,
              margin: EdgeInsets.only(right: i == 2 ? 0 : 6),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFE97777)
                    : const Color(0xFFE97777).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  final int index;
  const _RecommendedCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFFFB44A),
      const Color(0xFF5AC8FA),
      const Color(0xFF7F9CF5),
      const Color(0xFF52D1C6),
      const Color(0xFF9AA5B1),
    ];
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: colors[index % colors.length],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    );
  }
}

class _PopularList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: List.generate(3, (i) => _PopularCard(index: i)));
  }
}

class _PopularCard extends StatelessWidget {
  final int index;
  const _PopularCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.10),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Color(0xFF7F9CF5), Color(0xFF5A67D8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  index == 0
                      ? 'The Steal Like An Artist'
                      : index == 1
                      ? 'Laws of UX'
                      : 'A Million To One',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  index == 0
                      ? 'Austin Kleon'
                      : index == 1
                      ? 'Jon Yablonski'
                      : 'Tony Fadell',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                const Text(
                  '\$6.07',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  final book = mockBooks[index % mockBooks.length];
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BookDetailPage(book: book),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE97777),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Show Now'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  final book = mockBooks[index % mockBooks.length];
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BookDetailPage(book: book),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Learn More',
                  style: TextStyle(color: Colors.grey.shade800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------- MOCK DATA & MODELS ----------------------
class Book {
  final String id;
  final String title;
  final String author;
  final String description;
  final double price;
  final Color coverColor;
  final String pdfUrl;
  final double rating;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.price,
    required this.coverColor,
    required this.pdfUrl,
    required this.rating,
  });
}

const _lipsum =
    'A timeless guide that explores the psychology behind financial decisions.\n\n'
    'Discover stories that reveal how emotions and biases shape our wealth,\n'
    'and learn practical lessons to build long-term financial freedom.';

final List<Book> mockBooks = [
  Book(
    id: 'b1',
    title: 'The Psychology of Money',
    author: 'Morgan Housel',
    description: _lipsum,
    price: 6.07,
    coverColor: const Color(0xFF7F9CF5),
    pdfUrl:
        'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    rating: 4.8,
  ),
  Book(
    id: 'b2',
    title: 'Steal Like An Artist',
    author: 'Austin Kleon',
    description: _lipsum,
    price: 5.99,
    coverColor: const Color(0xFFFFB44A),
    pdfUrl: 'https://unec.edu.az/application/uploads/2014/12/pdf-sample.pdf',
    rating: 4.6,
  ),
  Book(
    id: 'b3',
    title: 'Laws of UX',
    author: 'Jon Yablonski',
    description: _lipsum,
    price: 7.49,
    coverColor: const Color(0xFF5AC8FA),
    pdfUrl: 'https://www.africau.edu/images/default/sample.pdf',
    rating: 4.7,
  ),
];

// ---------------------- BOOK DETAIL PAGE ----------------------
class BookDetailPage extends StatelessWidget {
  final Book book;
  const BookDetailPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Details',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 110,
                      height: 150,
                      decoration: BoxDecoration(
                        color: book.coverColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            book.author,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _StarRating(rating: book.rating),
                              const SizedBox(width: 8),
                              Text(
                                book.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _Chip(text: 'Finance'),
                              const SizedBox(width: 8),
                              _Chip(text: 'Psychology'),
                              const SizedBox(width: 8),
                              _Chip(text: 'Bestseller'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'About this book',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  book.description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PdfReaderPage(book: book),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE97777),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Read Now',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Buy for \$${book.price.toStringAsFixed(2)}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final double rating; // 0..5
  const _StarRating({required this.rating});
  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;
    return Row(
      children: List.generate(5, (i) {
        IconData icon;
        if (i < full) {
          icon = Icons.star_rounded;
        } else if (i == full && half) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }
        return Icon(icon, size: 18, color: const Color(0xFFFFC107));
      }),
    );
  }
}

// ---------------------- PDF READER PAGE (with highlight saving) ----------------------
class PdfReaderPage extends StatefulWidget {
  final Book book;
  const PdfReaderPage({super.key, required this.book});

  @override
  State<PdfReaderPage> createState() => _PdfReaderPageState();
}

class _PdfReaderPageState extends State<PdfReaderPage> {
  final PdfViewerController _controller = PdfViewerController();
  final List<_TextHighlight> _highlights = [];
  String _currentSelection = '';
  int _currentPageForSelection = 0;
  bool _showSaveBar = false;

  void _handleSelection(PdfTextSelectionChangedDetails details) {
    final selectedText = details.selectedText ?? '';
    setState(() {
      _currentSelection = selectedText.trim();
      _currentPageForSelection = _controller.pageNumber;
      _showSaveBar = _currentSelection.isNotEmpty;
    });
  }

  void _saveCurrentHighlight() {
    if (_currentSelection.isEmpty) return;
    setState(() {
      _highlights.add(
        _TextHighlight(
          pageNumber: _currentPageForSelection,
          text: _currentSelection,
          createdAt: DateTime.now(),
        ),
      );
      _showSaveBar = false;
    });
    _controller.clearSelection();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved highlight')));
  }

  Future<void> _jumpToHighlight(_TextHighlight h) async {
    // Try to search the exact text then jump to first occurrence
    final result = await _controller.searchText(h.text);
    if (result.totalInstanceCount > 0) {
      result.nextInstance();
    } else {
      // Fallback: go to stored page
      _controller.jumpToPage(h.pageNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          widget.book.title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Highlights',
            icon: const Icon(
              Icons.format_color_text_rounded,
              color: Colors.black87,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) => _HighlightsSheet(
                  highlights: _highlights,
                  onTapItem: (h) {
                    Navigator.of(context).pop();
                    _jumpToHighlight(h);
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SfPdfViewer.network(
            widget.book.pdfUrl,
            controller: _controller,
            canShowScrollHead: true,
            canShowPaginationDialog: true,
            onTextSelectionChanged: _handleSelection,
          ),
          if (_showSaveBar)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.highlight_rounded,
                      color: Color(0xFFE97777),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Save highlight?',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        setState(() => _showSaveBar = false);
                        _controller.clearSelection();
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      onPressed: _saveCurrentHighlight,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE97777),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TextHighlight {
  final int pageNumber;
  final String text;
  final DateTime createdAt;
  _TextHighlight({
    required this.pageNumber,
    required this.text,
    required this.createdAt,
  });
}

class _HighlightsSheet extends StatelessWidget {
  final List<_TextHighlight> highlights;
  final void Function(_TextHighlight) onTapItem;
  const _HighlightsSheet({required this.highlights, required this.onTapItem});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Highlights',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (highlights.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No highlights yet',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: highlights.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (ctx, i) {
                    final h = highlights[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        h.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                      subtitle: Text(
                        'Page ${h.pageNumber} • ${_formatTime(h.createdAt)}',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => onTapItem(h),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
