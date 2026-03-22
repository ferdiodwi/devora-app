import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../book_detail_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<dynamic> _books = [];
  Map<String, dynamic>? _user;
  List<dynamic> _loans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    final bookRes = await ApiService.getBooks();
    final profRes = await ApiService.getProfile();
    final loanRes = await ApiService.getLoans();
    
    if (mounted) {
      setState(() {
        if (bookRes['status'] == 200) _books = bookRes['data']['data'] ?? [];
        if (profRes['status'] == 200) _user = profRes['data']['user'];
        if (loanRes['status'] == 200) _loans = loanRes['data']['data'] ?? [];
        _isLoading = false;
      });
    }
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final member = _user?['member'];
    final memberCode = member?['member_code'] ?? 'MEMBER-XXXX';
    final activeLoansCount = _loans.where((l) => l['status'] != 'returned').length;
    final userName = _user?['name'] ?? 'Pengguna';
    final firstName = userName.split(' ').first;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async => _fetchData(),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  children: [
                    // Header Area
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getGreeting()},',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              firstName,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B5A41).withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF2B5A41).withOpacity(0.2), width: 2),
                          ),
                          child: Center(
                            child: Text(
                              firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B5A41), fontSize: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Modern Digital Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2B5A41), Color(0xFF1A3626)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF2B5A41).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -20,
                            top: -20,
                            child: Icon(Icons.menu_book, size: 100, color: Colors.white.withOpacity(0.05)),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'KARTU PERPUSTAKAAN',
                                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'SMA NEGERI 4 JEMBER',
                                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
                                  )
                                ],
                              ),
                              const SizedBox(height: 32),
                              Text(
                                memberCode,
                                style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 2, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('NAMA ANGGOTA', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
                                      const SizedBox(height: 4),
                                      Text(userName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('PINJAMAN AKTIF', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
                                      const SizedBox(height: 4),
                                      Text('$activeLoansCount Buku', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Quick Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
                        ],
                      ),
                      child: TextField(
                        readOnly: true, // redirect logic if needed
                        decoration: InputDecoration(
                          hintText: 'Cari buku, e-book, atau penulis...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF2B5A41)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Katalog Terbaru', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        Text('Lihat Semua', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Horizontal Books List
                    _books.isEmpty
                        ? Container(
                            height: 200,
                            alignment: Alignment.center,
                            child: const Text('Belum ada data buku.', style: TextStyle(color: Colors.grey)),
                          )
                        : SizedBox(
                            height: 300,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _books.length > 5 ? 5 : _books.length, // Only show 5 terbaru
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
                                    width: 150,
                                    margin: const EdgeInsets.only(right: 20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            width: 150,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                              image: book['cover_image'] != null
                                                  ? DecorationImage(
                                                      image: NetworkImage(book['cover_image']),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                              boxShadow: [
                                                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 8))
                                              ],
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
                                        const SizedBox(height: 16),
                                        Text(
                                          book['title'] ?? 'Tanpa Judul',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, height: 1.2, color: Color(0xFF1E293B)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          book['author'] ?? '-',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}
