import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';

class BookQuoteBox extends StatefulWidget {
  const BookQuoteBox({Key? key}) : super(key: key);
  @override
  State<BookQuoteBox> createState() => _BookQuoteBoxState();
}

class _BookQuoteBoxState extends State<BookQuoteBox>
    with AutomaticKeepAliveClientMixin {
  final bookQuotes = [
    {
      'quote':
          'Chính từ sách mà những người khôn ngoan tìm được sự an ủi khỏi những rắc rối của cuộc đời.',
      'author': 'Victor Hugo',
    },
    {
      'quote': 'Sách là ngọn đèn bất diệt của trí tuệ con người.',
      'author': 'Ngạn ngữ Nga',
    },
    {'quote': 'Sách nằm im là sách chết.', 'author': 'Ngạn ngữ Nga'},
    {
      'quote': 'Sách là ngọn đèn bất diệt của trí tuệ con người.',
      'author': 'Ngạn ngữ Nga',
    },
  ];
  late int _index;
  @override
  void initState() {
    super.initState();
    _randomize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _randomize();
  }

  void _randomize() {
    final rand = Random();
    _index = rand.nextInt(bookQuotes.length);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final selected = bookQuotes[_index];
    // Responsive scale based on device width (baseline ~360)
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 360).clamp(0.85, 1.25);
    final borderRadius = 12 * scale;
    final iconSize = 14 * scale;
    final quoteFontSize = 12 * scale;
    final authorFontSize = 10 * scale;
    final vMargin = (12 * scale).clamp(8.0, 16.0);
    final vPadding = (8 * scale).clamp(6.0, 12.0);
    final hPadding = (12 * scale).clamp(10.0, 16.0);
    // Estimate height from content to avoid extra blank space
    const quoteLineHeight = 1.3;
    final smallSpacing = 2 * scale;
    final estimatedQuoteHeight = quoteFontSize * quoteLineHeight * 2; // 2 lines
    final estimatedAuthorHeight = authorFontSize * 1.2;
    final containerHeight =
        (vPadding * 2) +
        iconSize +
        smallSpacing +
        estimatedQuoteHeight +
        smallSpacing +
        estimatedAuthorHeight;
    return Container(
      margin: EdgeInsets.symmetric(vertical: vMargin, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC1C1), Color(0xFFFFEBEE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),

      child: GlassmorphicContainer(
        width: double.infinity,
        height: containerHeight,
        borderRadius: borderRadius,
        blur: 8,
        alignment: Alignment.center,
        border: 0.8,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.20),
            Colors.white.withOpacity(0.08),
          ],
          stops: const [0.1, 1],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.35),
            Colors.white.withOpacity(0.05),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: vPadding,
            horizontal: hPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.format_quote,
                color: Colors.red.shade400,
                size: iconSize,
              ),
              SizedBox(height: smallSpacing),
              Text(
                '"${selected['quote']}"',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFF2D2D2D),
                  fontSize: quoteFontSize,
                  fontStyle: FontStyle.italic,
                  height: quoteLineHeight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: smallSpacing),
              Text(
                '- ${selected['author']} -',
                style: GoogleFonts.montserrat(
                  color: Colors.black.withOpacity(0.6),
                  fontSize: authorFontSize,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
