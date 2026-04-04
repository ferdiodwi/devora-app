import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../book_detail_screen.dart';
import 'ebook_tab.dart';

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
  String _activeFilter = 'Semua';

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
        _applyFilters();
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterBooks(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _activeFilter = filter;
      _applyFilters();
    });
  }

  void _applyFilters() {
    // 1. Filter by Search Query
    if (_searchQuery.isEmpty) {
      _filteredBooks = List.from(_books);
    } else {
      _filteredBooks = _books.where((book) {
        final title = (book['title'] ?? '').toString().toLowerCase();
        final author = (book['author'] ?? '').toString().toLowerCase();
        final q = _searchQuery.toLowerCase();
        return title.contains(q) || author.contains(q);
      }).toList();
    }

    // 2. Sort by Active Filter
    if (_activeFilter == 'Terbaru') {
      _filteredBooks.sort((a, b) {
        final int idA = a['id'] ?? 0;
        final int idB = b['id'] ?? 0;
        return idB.compareTo(idA); // Descending ID
      });
    } else if (_activeFilter == 'Populer') {
      _filteredBooks.sort((a, b) {
        final int loanA = a['loan_count'] ?? 0;
        final int loanB = b['loan_count'] ?? 0;
        return loanB.compareTo(loanA); // Descending Loan Count
      });
    }
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _activeFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onFilterChanged(label),
      selectedColor: const Color(0xFF2B5A41),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey.shade200,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAF8),
        appBar: AppBar(
          title: const Text('Katalog', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFF2B5A41),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF2B5A41),
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Buku Fisik'),
              Tab(text: 'E-Book'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPhysicalBookView(),
            const EbookTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhysicalBookView() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
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
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Semua'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Terbaru'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Populer'),
                  ],
                ),
              ),
            ],
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
    );
  }
}
