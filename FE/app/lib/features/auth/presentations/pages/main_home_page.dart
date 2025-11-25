// lib/features/auth/presentations/pages/main_home_page.dart
//
// removed unused imports for cleaner build
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:book_tech/core/ui/app_top_bar.dart';
import 'package:book_tech/core/widgets/gradient_background.dart';
//
import 'package:book_tech/features/auth/presentations/widgets/home/new_navigation.dart'
    as new_navigation;
//
import '../providers/document_provider.dart';
import '../pages/search_page.dart';
import '../pages/latest_documents_page.dart';
import '../widgets/document/genre_section.dart';
//
import '../widgets/home/book_quote_box.dart';
import 'package:flutter_animate/flutter_animate.dart';
// removed: carousel slider (replaced by promo pills)
import 'package:shimmer/shimmer.dart';
import 'package:book_tech/features/auth/data/models/genre_model.dart';
import 'package:chips_choice/chips_choice.dart';
import 'package:book_tech/features/auth/presentations/pages/most_borrowed_documents_page.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});
  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  // Segmented control state
  int? _selectedGenreId; // null means show default sections

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      docProvider.loadGenres(context); // Load genres trước
    });
  }

  void _showNavigationModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(2, 0),
                ),
              ],
            ),
            child: const new_navigation.NavigationDrawer(),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(-1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
          child: child,
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppTopBar(
          title: 'Trang chủ',
          leadingType: AppTopBarLeading.menu,
          // onLeadingTap: () => _showNavigationModal(context),
          actions: [
            AppTopBarAction.search(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Quote slider moved up
                  //const _QuoteSliderBar(),

                  // Quick actions
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = constraints.maxWidth;
                      final isSmallScreen = screenWidth < 360;
                      final horizontalPadding = isSmallScreen ? 12.0 : 16.0;
                      final spacing = isSmallScreen ? 6.0 : 8.0;
                      
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.grid_view_rounded,
                                label: 'Thể loại',
                                color: const Color(0xFFFF1744),
                                isSmallScreen: isSmallScreen,
                                onTap: () {
                                  Navigator.of(context).pushNamed('/genre');
                                },
                              ),
                            ),
                            SizedBox(width: spacing),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.library_books_rounded,
                                label: 'Phổ biến',
                                color: const Color(0xFF2979FF),
                                isSmallScreen: isSmallScreen,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const MostBorrowedDocumentsPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: spacing),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.favorite_rounded,
                                label: 'Mới nhất',
                                color: const Color(0xFFFF6D00),
                                isSmallScreen: isSmallScreen,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const LatestDocumentsPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Fixed filter bar (stays while books scroll)
                  Consumer<DocumentProvider>(
                    builder: (context, provider, _) {
                      final List<GenreModel> chips = provider.genres;
                      final List<String> labels = [
                        'Tất cả',
                        ...chips.map((g) => g.name),
                      ];
                      final List<int?> values = [
                        null,
                        ...chips.map((g) => g.genreId),
                      ];
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isSmallScreen = constraints.maxWidth < 360;
                          final horizontalPadding = isSmallScreen ? 12.0 : 16.0;
                          
                          return Padding(
                            padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 8),
                            child: ChipsChoice<int?>.single(
                              value: _selectedGenreId,
                              onChanged: (val) =>
                                  setState(() => _selectedGenreId = val),
                              choiceItems: C2Choice.listFrom<int?, String>(
                                source: labels,
                                value: (i, v) => values[i],
                                label: (i, v) => v,
                              ),
                              choiceStyle: C2ChipStyle.filled(
                                color: const Color(0xFFF1F1F1),
                                selectedStyle: C2ChipStyle.filled(
                                  color: const Color(0xFFFFCDD2),
                                ),
                              ),
                              wrapped: false,
                              scrollPhysics: const BouncingScrollPhysics(),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // Content based on selected tab
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < 360;
                        final horizontalPadding = isSmallScreen ? 12.0 : 16.0;
                        
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 16),
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Consumer<DocumentProvider>(
                            builder: (context, documentProvider, child) {
                              if (documentProvider.isLoadingGenres) {
                                return _LoadingBooksRow();
                              }
                              // Filtered sections: show selected genre only, else default 2
                              final selectedId = _selectedGenreId;
                              if (selectedId != null) {
                                final genre = documentProvider.genres
                                    .firstWhere(
                                      (g) => g.genreId == selectedId,
                                      orElse: () =>
                                          documentProvider.genres.isNotEmpty
                                          ? documentProvider.genres.first
                                          : GenreModel(
                                              genreId: -1,
                                              name: 'Không có',
                                            ),
                                    );
                                if (genre.genreId == -1) {
                                  return const SizedBox.shrink();
                                }
                                return GenreSectionWidget(
                                      key: ValueKey<int>(genre.genreId),
                                      genre: genre,
                                      documentProvider: documentProvider,
                                    )
                                    .animate()
                                    .fadeIn(duration: 250.ms)
                                    .move(
                                      begin: const Offset(0, 12),
                                      end: Offset.zero,
                                    );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: documentProvider.genres.map((genre) {
                                  return GenreSectionWidget(
                                        key: ValueKey<int>(genre.genreId),
                                        genre: genre,
                                        documentProvider: documentProvider,
                                      )
                                      .animate()
                                      .fadeIn(duration: 250.ms)
                                      .move(
                                        begin: const Offset(0, 12),
                                        end: Offset.zero,
                                      );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                        );
                      },
                    ),
                  ),
                  // Removed tiny 4 buttons grid per request
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// removed: old banner card (replaced by promo pills)

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isSmallScreen;

  const _QuickAction({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isSmallScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Responsive sizing
    final iconSize = isSmallScreen ? 48.0 : 56.0;
    final iconInnerSize = isSmallScreen ? 22.0 : 24.0;
    final fontSize = isSmallScreen ? 11.5 : 13.0;
    final verticalSpacing = isSmallScreen ? 4.0 : 6.0;
    
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: iconInnerSize),
            ),
            SizedBox(height: verticalSpacing),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E1E1E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingBooksRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: SizedBox(
        height: 180,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            return Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: 124,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuoteSliderBar extends StatefulWidget {
  const _QuoteSliderBar();

  @override
  State<_QuoteSliderBar> createState() => _QuoteSliderBarState();
}

class _QuoteSliderBarState extends State<_QuoteSliderBar> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.95);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: PageView.builder(
        controller: _controller,
        padEnds: false,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(
              left: 14,
              right: 8,
              top: 8,
              bottom: 8,
            ),
            child: BookQuoteBox(),
          );
        },
      ),
    );
  }
}
