import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
      return const Scaffold(backgroundColor: Color(0xFFF7FAF8), body: Center(child: CircularProgressIndicator()));
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
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        title: const Text('SMA NEGERI 4 JEMBER', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _fetchProfile(),
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Avatar Section
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3C7A5), // Peach bg
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: Center(
                      child: Text(
                        _user!['name']?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B5A41),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _user!['name'] ?? 'User',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              member['type']?.toString().toUpperCase() ?? 'MEMBER',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Color(0xFF679B7B)),
            ),
            const SizedBox(height: 40),

            // Library Attendance Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  const Text('LIBRARY ATTENDANCE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                  const SizedBox(height: 16),
                  Container(
                    width: 200,
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF8B9B90), Color(0xFF5A6A60)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: QrImageView(
                          data: member['member_code'] ?? 'SMAN4JEMBER',
                          version: QrVersions.auto,
                          size: 150,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Member ID', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    member['member_code'] ?? 'DEV-XXXX-XXX',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Text('12', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2B5A41))),
                          const SizedBox(height: 4),
                          Text('VISITS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1)),
                        ],
                      ),
                      Container(width: 1, height: 30, color: Colors.grey.shade200),
                      Column(
                        children: [
                          const Text('04', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2B5A41))),
                          const SizedBox(height: 4),
                          Text('BOOKS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1)),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Detail Data Anggota Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text('INFORMASI DETAIL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                   const SizedBox(height: 24),
                    Wrap(
                     spacing: 24,
                     runSpacing: 24,
                     children: [
                       _detailItem('AKUN LOGIN', _user!['email']?.toString() ?? '-', width: double.infinity),
                       _detailItem('NO. HANDPHONE', member['phone']?.toString() ?? '-'),
                       _detailItem('TGL BERGABUNG', member['created_at']?.toString().split('T').first ?? '-'),
                       if (member['type'] == 'siswa') ...[
                         _detailItem('NIS', member['nis_nip']?.toString() ?? '-'),
                         _detailItem('NISN', member['nisn']?.toString() ?? '-'),
                         _detailItem('KELAS', member['kelas'] is Map ? (member['kelas']['nama_kelas'] ?? member['kelas']['name'] ?? '-') : (member['kelas']?.toString() ?? '-')),
                       ] else if (member['type'] == 'guru' || member['type'] == 'karyawan') ...[
                         _detailItem('NIP', member['nis_nip']?.toString() ?? '-'),
                       ],
                       _detailItem('NIK', member['nik']?.toString() ?? '-'),
                       _detailItem('TTL', '${member['tempat_lahir'] ?? '-'}, ${member['tanggal_lahir'] ?? '-'}'),
                       _detailItem('JENIS KELAMIN', member['jenis_kelamin']?.toString() ?? '-'),
                       _detailItem('ALAMAT', member['alamat']?.toString() ?? '-', width: double.infinity),
                     ],
                   ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings buttons
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                  child: const Icon(Icons.settings, color: Colors.black87),
                ),
                title: const Text('Account Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.logout, color: Colors.red),
                ),
                title: const Text('Logout Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                onTap: _logout,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value, {double width = 130}) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }
}

