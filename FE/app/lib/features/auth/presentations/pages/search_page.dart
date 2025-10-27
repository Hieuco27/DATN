import 'package:book_tech/features/auth/presentations/pages/document_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/document/search_suggest_item.dart';
import '../../data/models/document_response_model.dart';
import '../providers/search_provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto focus vào search field khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    searchProvider.searchDocuments(query, context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _performSearch,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm sách, tác giả...',
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: const Color.fromARGB(255, 0, 0, 0),
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: const Color.fromARGB(255, 0, 0, 0),
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              Provider.of<SearchProvider>(
                                context,
                                listen: false,
                              ).clearSearch();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Hủy',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          if (searchProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (searchProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi tìm kiếm',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    searchProvider.error!,
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _performSearch(_searchController.text),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (searchProvider.searchResults.isEmpty &&
              searchProvider.currentQuery.isNotEmpty) {
            return const Center(
              child: Text(
                'Không tìm thấy kết quả',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          if (searchProvider.searchResults.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Nhập từ khóa để tìm kiếm',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  if (searchProvider.searchHistory.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Lịch sử tìm kiếm:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...searchProvider.searchHistory
                        .take(5)
                        .map(
                          (history) => ListTile(
                            leading: const Icon(Icons.history, size: 16),
                            title: Text(history),
                            // Trong SearchSuggestionItem onTap
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DocumentDetailPage(
                                    documentId: history.hashCode,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  ],
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: searchProvider.searchResults.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final document = searchProvider.searchResults[index];
              return SearchSuggestionItem(
                document: document,
                onTap: () {
                  // Navigate to document detail
                  Navigator.pushNamed(
                    context,
                    '/document-detail',
                    arguments: document.documentId,
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
