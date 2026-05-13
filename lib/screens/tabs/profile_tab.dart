import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';
import '../settings_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isUploadingAvatar = false;
  int _totalLoans = 0;
  int _activeLoans = 0;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  void _fetchProfile() async {
    final res = await ApiService.getProfile();
    final loanRes = await ApiService.getLoans();
    if (res['status'] == 200 && mounted) {
      setState(() {
        _user = res['data']['user'];
        if (loanRes['status'] == 200) {
          final loans = loanRes['data']['data'] as List? ?? [];
          _totalLoans = loans.length;
          _activeLoans = loans.where((l) => l['status'] != 'returned' && l['status'] != 'selesai').length;
        }
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

  // ─── Upload Avatar ─────────────────────────────────────────
  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(5)),
            ),
            const SizedBox(height: 24),
            const Text('Ubah Foto Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _sourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    color: const Color(0xFF2B5A41),
                    bgColor: const Color(0xFFE8F1EC),
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _sourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    color: const Color(0xFF1565C0),
                    bgColor: const Color(0xFFE3F2FD),
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 800);
    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);
    final res = await ApiService.uploadAvatar(File(picked.path));
    if (!mounted) return;
    setState(() => _isUploadingAvatar = false);

    if (res['status'] == 200) {
      _fetchProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Foto profil berhasil diperbarui!', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: const Color(0xFF2B5A41),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['data']['message'] ?? 'Gagal mengunggah foto'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    }
  }

  Widget _sourceOption({required IconData icon, required String label, required Color color, required Color bgColor, required VoidCallback onTap}) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 10),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Avatar Widget ─────────────────────────────────────────
  Widget _buildAvatar(Map<String, dynamic>? member) {
    final String? photoPath = member?['photo']?.toString();
    final String baseUrl = ApiService.baseUrl.replaceAll('/api/v1', '').replaceAll('/api', '');
    final String? photoUrl = (photoPath != null && photoPath.isNotEmpty) ? '$baseUrl/storage/$photoPath' : null;

    return GestureDetector(
      onTap: _pickAndUploadAvatar,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7F5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(color: const Color(0xFF2B5A41).withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: ClipOval(
              child: _isUploadingAvatar
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2B5A41), strokeWidth: 3))
                  : photoUrl != null
                      ? Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _avatarInitial())
                      : _avatarInitial(),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2B5A41),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _avatarInitial() {
    return Center(
      child: Text(
        _user?['name']?.substring(0, 1).toUpperCase() ?? 'U',
        style: const TextStyle(fontSize: 40, color: Color(0xFF2B5A41), fontWeight: FontWeight.w800),
      ),
    );
  }

  // ─── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_isLoading) {
      return const Scaffold(backgroundColor: Color(0xFFF4F7F5), body: Center(child: CircularProgressIndicator(color: Color(0xFF2B5A41))));
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
      backgroundColor: const Color(0xFFF4F7F5),
      body: RefreshIndicator(
        onRefresh: () async => _fetchProfile(),
        color: const Color(0xFF2B5A41),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Stack(
            children: [
              // ─── GREEN HEADER ─────────────────────────────
              Container(
                height: size.height * 0.28,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF2B5A41),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Profil Pengguna',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── FLOATING CONTENT ──────────────────────────
              Padding(
                padding: EdgeInsets.only(top: size.height * 0.12, left: 20, right: 20, bottom: 40),
                child: Column(
                  children: [
                    // Avatar & Basic Info Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF2B5A41).withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 15))
                        ],
                      ),
                      child: Column(
                        children: [
                          Transform.translate(
                            offset: const Offset(0, -50),
                            child: _buildAvatar(member),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -30),
                            child: Column(
                              children: [
                                Text(
                                  _user!['name'] ?? 'User',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F1EC),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    member['type']?.toString().toUpperCase() ?? 'MEMBER',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w800, color: Color(0xFF2B5A41)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ─── Library Attendance Card ──────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF2B5A41).withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text('KARTU IDENTITAS VIRTUAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF2B5A41), letterSpacing: 1)),
                          const SizedBox(height: 24),
                          Container(
                            width: 180,
                            height: 180,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              border: Border.all(color: Colors.grey.shade200, width: 2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: QrImageView(
                                data: member['member_code'] ?? 'SMAN4JEMBER',
                                version: QrVersions.auto,
                                size: 140,
                                backgroundColor: const Color(0xFFF9FAFB),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text('ID Anggota', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            member['member_code'] ?? 'DEV-XXXX-XXX',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(children: [
                                Text('$_activeLoans', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF2B5A41))),
                                const SizedBox(height: 2),
                                Text('PINJAMAN AKTIF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1)),
                              ]),
                              Container(width: 1, height: 40, color: Colors.grey.shade200),
                              Column(children: [
                                Text('$_totalLoans', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF2B5A41))),
                                const SizedBox(height: 2),
                                Text('TOTAL BUKU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1)),
                              ]),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── Detail Informasi Card ────────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF2B5A41).withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('INFORMASI DETAIL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF2B5A41), letterSpacing: 1)),
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
                    const SizedBox(height: 32),

                    // ─── Action Buttons ─────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF2B5A41).withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(color: Color(0xFFE8F1EC), shape: BoxShape.circle),
                              child: const Icon(Icons.settings_rounded, color: Color(0xFF2B5A41)),
                            ),
                            title: const Text('Pengaturan Akun', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1E293B))),
                            subtitle: Text('Ubah password & nomor handphone', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                            trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                              if (mounted) _fetchProfile();
                            },
                          ),
                          Divider(height: 1, color: Colors.grey.shade100, indent: 70, endIndent: 20),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                              child: Icon(Icons.logout_rounded, color: Colors.red.shade600),
                            ),
                            title: Text('Keluar Aplikasi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.red.shade600)),
                            onTap: _logout,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}
