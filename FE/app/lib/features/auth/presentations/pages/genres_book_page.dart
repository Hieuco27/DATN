import 'package:book_tech/features/auth/presentations/bloc/auth_bloc.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';
import '../widgets/document/document_item.dart';
import '../../domain/entities/document_entity.dart';
import '../../data/models/genre_model.dart';

class GenreBooksPage extends StatefulWidget {
  final String genreName;
  final int? genreId;

  const GenreBooksPage({Key? key, required this.genreName, this.genreId})
    : super(key: key);

  @override
  State<GenreBooksPage> createState() => _GenreBooksPageState();
}

class _GenreBooksPageState extends State<GenreBooksPage> {
  List<DocumentEntity> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final documentProvider = Provider.of<DocumentProvider>(
        context,
        listen: false,
      );
      // Lấy access token từ AuthBloc
      final authBloc = context.read<AuthBloc>();
      String accessToken = '';
      if (authBloc.state is AuthAuthenticated) {
        final authState = authBloc.state as AuthAuthenticated;
        accessToken = authState.account.accessToken!;
      }
      // Lấy tất cả documents và filter theo genre nếu cần
      final allDocuments = await documentProvider.getDocumentsForReader(
        accessToken: '', // Bạn cần lấy access token từ AuthBloc
        limit: 100,
      );

      if (widget.genreId != null) {
        _documents = await documentProvider.getDocumentsByGenre(
          accessToken: accessToken,
          genreId: widget.genreId!,
          limit: 100,
        );
      } else {
        _documents = await documentProvider.getDocumentsForReader(
          accessToken: accessToken,
          limit: 100,
        );
      }
    } catch (e) {
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.genreName,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
          ? const Center(
              child: Text(
                'Không có tài liệu nào',
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final isSmallScreen = screenWidth < 360;
                final isMediumScreen = screenWidth < 380;
                
                // Responsive values
                final padding = isSmallScreen ? 12.0 : 16.0;
                final spacing = isSmallScreen ? 10.0 : 12.0;
                final crossAxisCount = isSmallScreen ? 2 : 3;
                // Điều chỉnh childAspectRatio để tránh overflow (giảm tỷ lệ width/height => tăng chiều cao)
                final childAspectRatio = isSmallScreen ? 0.48 : (isMediumScreen ? 0.45 : 0.42);
                
                return SafeArea(
                  child: GridView.builder(
                    padding: EdgeInsets.all(padding),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                    ),
                    itemCount: _documents.length,
                    itemBuilder: (context, index) {
                      return DocumentItem(document: _documents[index]);
                    },
                  ),
                );
              },
            ),
    );
  }
}
