import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  void _fetchProfile() async {
    final res = await ApiService.getProfile();
    if (res['status'] == 200 && mounted) {
      setState(() {
        _user = res['data']['user'];
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Gagal memuat profil.'),
              TextButton(onPressed: _logout, child: const Text('Logout'))
            ],
          ),
        ),
      );
    }

    final member = _user!['member'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _fetchProfile(),
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.deepPurple.shade100,
                child: Text(
                  _user!['name']?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(fontSize: 40, color: Colors.deepPurple),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _user!['name'] ?? 'Tidak ada nama',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              member['type']?.toString().toUpperCase() ?? 'Anggota',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 1)
                ],
              ),
              child: Column(
                children: [
                   const Text(
                    'Barcode Identitas',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tunjukkan QR Token ini untuk presensi perpustakaan.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 24),
                  // Placeholder for QR Code (could use qr_flutter package later)
                  Container(
                    width: 150,
                    height: 150,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 2)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_2, size: 80, color: Colors.black87),
                        Text(member['qr_token']?.split('-').first ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10))
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Kode Member: ${member['member_code'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (member['nis_nip'] != null) Text('NIS/NIP: ${member['nis_nip']}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
