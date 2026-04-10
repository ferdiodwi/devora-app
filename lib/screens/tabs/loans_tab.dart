import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../book_reader_screen.dart';
import '../../widgets/notification_bell.dart';

class LoansTab extends StatefulWidget {
  const LoansTab({super.key});

  @override
  State<LoansTab> createState() => _LoansTabState();
}

String _filter = 'semua';

class _LoansTabState extends State<LoansTab>
    with SingleTickerProviderStateMixin {
  String formatDate(String? date) {
    if (date == null) return '-';
    final d = DateTime.tryParse(date);
    if (d == null) return '-';

    return "${d.day}/${d.month}/${d.year}";
  }

  List<dynamic> _loans = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchLoans();
  }

  void _fetchLoans() async {
    final loanRes = await ApiService.getLoans();
    final ebookRes = await ApiService.getAllReadingProgress();

    List<dynamic> combined = [];

    if (loanRes['status'] == 200) {
      combined.addAll(loanRes['data']['data'] ?? []);
    }

    for (var ebook in ebookRes) {
      final detail = await ApiService.getEbookDetail(ebook['ebook_id']);

      int current = ebook['current_page'] ?? 0;
      int total = ebook['total_page'] ?? 0;

      String status = (total > 0 && current >= total) ? 'selesai' : 'aktif';

      combined.add({
        'type': 'ebook',
        'status': status,
        'book': {
          'title': detail['data']['title'],
          'cover_image': detail['data']['cover_image'],
          'author': '-',
        },
        'ebook_id': ebook['ebook_id'],
        'current_page': current,
        'total_page': total,
        'pdf_link': detail['data']['pdf_link'],
        'updated_at': ebook['updated_at'],
      });
    }

    setState(() {
      _loans = combined;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredLoans = _loans.where((l) {
      if (_filter == 'ebook') return l['type'] == 'ebook';
      if (_filter == 'fisik') return l['type'] != 'ebook';
      return true;
    }).toList();

    final activeLoans = filteredLoans
        .where((l) => l['status'] != 'selesai')
        .toList();

    final pastLoans = filteredLoans
        .where((l) => l['status'] == 'selesai')
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        title: const Text(
          'Devora',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [NotificationBell()],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pinjaman',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kelola buku yang sedang Anda baca.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  labelColor: const Color(0xFF2B5A41),
                  unselectedLabelColor: Colors.grey,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Aktif'),
                    Tab(text: 'Selesai'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  _buildFilterButton('Semua', 'semua'),
                  const SizedBox(width: 8),
                  _buildFilterButton('E-Book', 'ebook'),
                  const SizedBox(width: 8),
                  _buildFilterButton('Fisik', 'fisik'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLoanList(activeLoans, true),
                        _buildLoanList(pastLoans, false),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _filter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2B5A41) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildLoanList(List<dynamic> loans, bool isActive) {
    if (loans.isEmpty) {
      return const Center(child: Text('Belum ada buku di kategori ini.'));
    }
    return RefreshIndicator(
      onRefresh: () async => _fetchLoans(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        itemCount: loans.length,
        itemBuilder: (context, index) {
          final loan = loans[index];
          final book = loan['book'] ?? {};
          final isEbook = loan['type'] == 'ebook';

          DateTime? dueDate = loan['due_date'] != null
              ? DateTime.tryParse(loan['due_date'])
              : null;

          DateTime today = DateTime.now();

          String dateText;

          if (isEbook) {
            if (isActive) {
              dateText = "Dibaca terakhir: ${formatDate(loan['updated_at'])}";
            } else {
              dateText = "Selesai dibaca: ${formatDate(loan['updated_at'])}";
            }
          } else {
            if (isActive) {
              if (dueDate != null && today.isAfter(dueDate)) {
                dateText = "Terlambat (Seharusnya: ${loan['due_date']})";
              } else {
                dateText = "Pengembalian: ${loan['due_date']}";
              }
            } else {
              dateText = "Dikembalikan: ${loan['return_date']}";
            }
          }
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isEbook ? Colors.blue.shade50 : Colors.brown.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isEbook ? "E-BOOK" : "FISIK",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isEbook ? Colors.blue : Colors.brown,
                  ),
                ),
              ),
            ],
          );
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        image: book['cover_image'] != null
                            ? DecorationImage(
                                image: NetworkImage(book['cover_image']),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: book['cover_image'] == null
                          ? const Icon(Icons.book, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFFFE0A5)
                                  : const Color(0xFFE4F1E8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isActive
                                  ? 'BERJALAN'
                                  : (isEbook
                                        ? 'SELESAI DIBACA'
                                        : 'DIKEMBALIKAN'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? Colors.orange.shade900
                                    : const Color(0xFF2B5A41),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            book['title'] ?? 'Tanpa Judul',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            book['author'] ?? '-',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (isEbook) ...[
                            const SizedBox(height: 12),
                            Text(
                              "Halaman ${loan['current_page']} / ${loan['total_page']}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: (loan['total_page'] == 0)
                                  ? 0
                                  : loan['current_page'] / loan['total_page'],
                            ),
                          ],
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                dateText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isActive) ...[
                  const SizedBox(height: 20),

                  if (isEbook)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookReaderScreen(
                              url: loan['pdf_link'],
                              title: loan['book']['title'] ?? 'E-Book',
                              ebookId: loan['ebook_id'].toString(),
                              initialPage: (loan['current_page'] ?? 1),
                            ),
                          ),
                        );
                        _fetchLoans();
                      },
                      child: const Text("Lanjut Baca"),
                    )
                  else if (isActive)
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2B5A41),
                        side: const BorderSide(color: Color(0xFF2B5A41)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Perpanjang Pinjaman'),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
