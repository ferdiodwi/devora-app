import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class LoansTab extends StatefulWidget {
  const LoansTab({super.key});

  @override
  State<LoansTab> createState() => _LoansTabState();
}

class _LoansTabState extends State<LoansTab> {
  List<dynamic> _loans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pinjaman')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _fetchLoans(),
              child: _loans.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('Belum ada riwayat pinjaman buku.')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _loans.length,
                      itemBuilder: (context, index) {
                        final loan = _loans[index];
                        final isReturned = loan['status'] == 'selesai';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Kode Pinjam: ${loan['loan_code']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Chip(
                                      label: Text(
                                        loan['status'].toString().toUpperCase(),
                                        style: TextStyle(color: isReturned ? Colors.green : Colors.orange, fontSize: 12),
                                      ),
                                      backgroundColor: isReturned ? Colors.green.shade50 : Colors.orange.shade50,
                                      side: BorderSide.none,
                                    )
                                  ],
                                ),
                                const Divider(),
                                Text('Tanggal Pinjam: ${loan['loan_date'] ?? '-'}'),
                                Text('Jatuh Tempo: ${loan['due_date'] ?? '-'}'),
                                if (loan['return_date'] != null) Text('Waktu Kembali: ${loan['return_date']}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
