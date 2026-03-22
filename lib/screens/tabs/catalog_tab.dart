import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../book_detail_screen.dart';

class CatalogTab extends StatefulWidget {
  const CatalogTab({super.key});

  @override
  State<CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<CatalogTab> {
  List<dynamic> _books = [];
  List<dynamic> _filteredBooks = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  void _fetchBooks() async {
    final res = await ApiService.getBooks();
    if (res['status'] == 200 && mounted) {
      setState(() {
        _books = res['data']['data'] ?? [];
        _filteredBooks = _books;
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterBooks(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredBooks = _books;
      } else {
        _filteredBooks = _books.where((book) {
          final title = (book['title'] ?? '').toString().toLowerCase();
          final author = (book['author'] ?? '').toString().toLowerCase();
          final q = query.toLowerCase();
          return title.contains(q) || author.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        title: const Text('Katalog Buku', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: _filterBooks,
                decoration: InputDecoration(
                  hintText: 'Cari judul buku atau penulis...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  fillColor: const Color(0xFFF7FAF8),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredBooks.isEmpty
                      ? const Center(child: Text('Tidak ada buku ditemukan.'))
                      : RefreshIndicator(
                          onRefresh: () async => _fetchBooks(),
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.58,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _filteredBooks.length,
                            itemBuilder: (context, index) {
                              final book = _filteredBooks[index];
                              final titleStr = book['title']?.toString() ?? 'B';
                              final initials = titleStr.length > 1 ? titleStr.substring(0, 2).toUpperCase() : titleStr.toUpperCase();

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                            image: book['cover_image'] != null
                                                ? DecorationImage(
                                                    image: NetworkImage(book['cover_image']),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                          ),
                                          child: book['cover_image'] == null 
                                            ? Center(
                                                child: Text(
                                                  initials,
                                                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: const Color(0xFF2B5A41).withOpacity(0.3)),
                                                ),
                                              ) 
                                            : null,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              book['title'] ?? 'Tanpa Judul',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              book['author'] ?? '-',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
