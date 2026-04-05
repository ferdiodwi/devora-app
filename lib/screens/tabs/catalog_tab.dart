import 'dart:async';
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
  bool _isLoading = true;
  String _searchQuery = '';
  String _activeFilter = 'Semua';

  // Pagination states
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchBooks();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _fetchBooks({bool reset = false}) async {
    if (reset) {
      setState(() {
        _page = 1;
        _books = [];
        _hasMore = true;
        _isLoading = true;
      });
    }

    if (!_hasMore) return;

    final res = await ApiService.getBooks(page: _page, q: _searchQuery, sort: _activeFilter);
    if (res['status'] == 200 && mounted) {
      final newBooks = res['data']['data'] ?? [];
      setState(() {
        _books.addAll(newBooks);
        _isLoading = false;
        _isLoadingMore = false;
        
        // Asumsi jika data baru kurang dari 20 (karena limit = 20), maka tidak ada lagi
        if (newBooks.length < 20) {
          _hasMore = false;
        }
      });
    } else {
      if (mounted) {
        setState(() { 
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _loadMore() {
    if (_hasMore && !_isLoadingMore && !_isLoading) {
      setState(() {
        _isLoadingMore = true;
        _page++;
      });
      _fetchBooks();
    }
  }

  void _filterBooks(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
        });
        _fetchBooks(reset: true);
      }
    });
  }

  void _onFilterChanged(String filter) {
    if (_activeFilter == filter) return; // Ignore if same
    setState(() {
      _activeFilter = filter;
    });
    _fetchBooks(reset: true);
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
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2B5A41)))
              : _books.isEmpty
                  ? const Center(child: Text('Tidak ada buku ditemukan.'))
                  : Stack(
                      children: [
                        RefreshIndicator(
                          onRefresh: () async => _fetchBooks(reset: true),
                          color: const Color(0xFF2B5A41),
                          child: GridView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: _isLoadingMore ? 80 : 16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.58,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _books.length,
                            itemBuilder: (context, index) {
                              final book = _books[index];
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
                        if (_isLoadingMore)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 2))
                                  ],
                                ),
                                child: const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF2B5A41),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
        ),
      ],
    );
  }
}
