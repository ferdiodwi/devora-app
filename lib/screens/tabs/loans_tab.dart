import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class LoansTab extends StatefulWidget {
  const LoansTab({super.key});

  @override
  State<LoansTab> createState() => _LoansTabState();
}

class _LoansTabState extends State<LoansTab> with SingleTickerProviderStateMixin {
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
    final res = await ApiService.getLoans();
    if (res['status'] == 200 && mounted) {
      setState(() {
        _loans = res['data']['data'] ?? [];
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeLoans = _loans.where((l) => l['status'] != 'selesai').toList();
    final pastLoans = _loans.where((l) => l['status'] == 'selesai').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        title: const Text('Devora', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
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
                   Text('Pinjaman', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                   SizedBox(height: 4),
                   Text('Kelola buku yang sedang Anda baca.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                height: 48,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
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
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
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
                            ? DecorationImage(image: NetworkImage(book['cover_image']), fit: BoxFit.cover)
                            : null,
                      ),
                      child: book['cover_image'] == null ? const Icon(Icons.book, color: Colors.grey) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFFFFE0A5) : const Color(0xFFE4F1E8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isActive ? 'BERJALAN' : 'DIKEMBALIKAN',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? Colors.orange.shade900 : const Color(0xFF2B5A41)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(book['title'] ?? 'Tanpa Judul', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(book['author'] ?? '-', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(isActive ? 'Kembali: ${loan['due_date']}' : 'Tgl: ${loan['return_date']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                if (isActive) ...[
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2B5A41),
                      side: const BorderSide(color: Color(0xFF2B5A41)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Perpanjang Pinjaman', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ]
              ],
            ),
          );
        },
      ),
    );
  }
}
