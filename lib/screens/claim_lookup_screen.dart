import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'claim_activate_screen.dart';

class ClaimLookupScreen extends StatefulWidget {
  const ClaimLookupScreen({super.key});

  @override
  State<ClaimLookupScreen> createState() => _ClaimLookupScreenState();
}

class _ClaimLookupScreenState extends State<ClaimLookupScreen> {
  final _nisNipCtrl = TextEditingController();
  bool _isLoading = false;

  void _lookup() async {
    if (_nisNipCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan NIS atau NIP Anda')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final res = await ApiService.claimLookup(_nisNipCtrl.text);
    setState(() => _isLoading = false);

    if (res['status'] == 200) {
      final memberData = res['data']['data'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClaimActivateScreen(memberData: memberData),
        ),
      );
    } else {
      String msg = res['data']['message'] ?? 'Data tidak ditemukan';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aktivasi Akun Anggota')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.badge, size: 64, color: Colors.deepPurple),
            const SizedBox(height: 16),
            const Text(
              'Masukkan Nomor Induk',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Masukkan NIS (untuk Siswa) atau NIP (untuk Guru/Karyawan) yang telah didaftarkan oleh sekolah.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nisNipCtrl,
              decoration: const InputDecoration(
                labelText: 'NIS / NIP',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _lookup,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Cari Data Saya', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
