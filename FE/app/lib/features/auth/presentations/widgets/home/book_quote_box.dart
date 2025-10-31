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
    // Thêm nhiều câu khác...
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC1C1), Color(0xFFFFEBEE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 180,
        borderRadius: 16,
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
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.format_quote, color: Colors.red.shade400, size: 28),
              const SizedBox(height: 8),
              Text(
                '"${selected['quote']}"',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFF2D2D2D),
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '- ${selected['author']} -',
                style: GoogleFonts.montserrat(
                  color: Colors.black.withOpacity(0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
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
