import 'package:flutter/material.dart';
import 'book_reader_screen.dart';
import '../../services/api_service.dart';

class BookDetailScreen extends StatefulWidget {
  final Map<String, dynamic> book;
  final bool isEbook;

  const BookDetailScreen({super.key, required this.book, this.isEbook = false});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  double progress = 0.0;
  int currentPage = 0;
  int totalPage = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isEbook) {
      fetchProgress();
    }
  }

  void fetchProgress() async {
    final res = await ApiService.getReadingProgress(
      widget.book['id'].toString(),
    );

    if (res['status'] == 200) {
      setState(() {
        currentPage = res['data']['current_page'] ?? 0;
        totalPage = res['data']['total_page'] ?? 0;

        progress = totalPage == 0 ? 0 : currentPage / totalPage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.black87),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.share, color: Colors.black87),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Section (Gradient + Book Cover)
            Container(
              padding: const EdgeInsets.only(top: 100, bottom: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFD6E3DB),
                    const Color(0xFFF7FAF8).withOpacity(0.0),
                  ],
                ),
              ),
              child: Center(
                child: Builder(
                  builder: (context) {
                    final titleStr = widget.book['title']?.toString() ?? 'B';
                    final initials = titleStr.length > 1
                        ? titleStr.substring(0, 2).toUpperCase()
                        : titleStr.toUpperCase();
                    return Container(
                      height: 280,
                      width: 190,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        image: widget.book['cover_image'] != null
                            ? DecorationImage(
                                image: NetworkImage(widget.book['cover_image']),
                                fit: BoxFit.cover,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: widget.book['cover_image'] == null
                          ? Center(
                              child: Text(
                                initials,
                                style: TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(
                                    0xFF2B5A41,
                                  ).withOpacity(0.3),
                                ),
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ),

            // Info Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.book['title'] ?? 'Tanpa Judul',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.book['author'] ?? 'Unknown Author',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B5A41),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatPill(
                        Icons.star,
                        widget.book['avg_rating']?.toString() ?? '4.8',
                        'RATING',
                        Colors.orange,
                      ),
                      _buildStatPill(
                        Icons.library_books,
                        widget.book['pages']?.toString() ?? '324',
                        'HALAMAN',
                        Colors.black87,
                      ),
                      if (!widget.isEbook)
                        _buildStatPill(
                          Icons.inventory_2,
                          '${widget.book['stock'] ?? 0}',
                          'TERSEDIA',
                          const Color(0xFF2B5A41),
                        )
                      else
                        _buildStatPill(
                          Icons.download,
                          '140',
                          'DIUNDUH',
                          const Color(0xFF2B5A41),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Sinopsis',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.book['synopsis'] ??
                        'Buku ini tidak memiliki sinopsis. Namun, dipastikan buku ini sangat menarik untuk dibaca dan menambah wawasan Anda di perpustakaan Devora Atheneum.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tags
                  Row(
                    children: [
                      if (widget.book['category']?['name'] != null)
                        _buildTag(
                          widget.book['category']['name']
                              .toString()
                              .toUpperCase(),
                        ),
                      const SizedBox(width: 8),
                      if (widget.book['publisher'] != null)
                        _buildTag(
                          widget.book['publisher'].toString().toUpperCase(),
                        ),
                    ],
                  ),
                  const SizedBox(
                    height: 120,
                  ), // padding for floating bottom bar
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.isEbook) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progress Membaca',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text("${(progress * 100).toInt()}%"),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                color: Theme.of(context).colorScheme.primary,
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 24),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isEbook ? 'FORMAT' : 'KETERSEDIAAN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isEbook
                          ? 'E-Book Digital'
                          : '${widget.book['stock'] ?? 0} Copy Fisik',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (widget.isEbook) {
                          print(widget.book); // 🔥 debug

                          String? url;
                          final id = widget.book['id']?.toString() ?? "";

                          // ❌ FILTER: bukan archive valid
                          if (id.contains('http')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ebook tidak bisa dibuka (bukan PDF valid)',
                                ),
                              ),
                            );
                            return;
                          }

                          // ❌ FILTER: file audio
                          if (id.toLowerCase().contains('mp3')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ini file audio, bukan ebook PDF',
                                ),
                              ),
                            );
                            return;
                          }

                          // ✅ coba dari formats dulu
                          final formats = widget.book['formats'];
                          if (formats != null && formats is Map) {
                            for (var entry in formats.entries) {
                              if (entry.key.toString().contains('pdf')) {
                                url = entry.value.toString();
                                break;
                              }
                            }
                          }

                          // ✅ fallback archive
                          if (url == null || url.isEmpty) {
                            final res = await ApiService.getEbookDetail(id);
                            url = res['data']['pdf_link'];
                          }

                          print("FINAL URL: $url");

                          // validasi akhir
                          if (url != null && url.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookReaderScreen(
                                  url: url!,
                                  title: widget.book['title'] ?? '',
                                  ebookId: id,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('PDF tidak tersedia'),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF679B7B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: Text(
                        widget.isEbook ? 'Mulai Membaca' : 'Pinjam di Perpus',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(
    IconData icon,
    String value,
    String label,
    Color iconColor,
  ) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
