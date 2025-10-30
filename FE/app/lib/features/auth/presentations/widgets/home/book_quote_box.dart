import 'package:flutter/material.dart';
import 'dart:math';

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
      margin: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 201, 100, 91),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '"${selected['quote']}"',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontStyle: FontStyle.italic,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '- ${selected['author']} -',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'cursive',
              fontStyle: FontStyle.italic,
              fontSize: 16,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
