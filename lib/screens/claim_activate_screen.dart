import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class ClaimActivateScreen extends StatefulWidget {
  final Map<String, dynamic> memberData;

  const ClaimActivateScreen({super.key, required this.memberData});

  @override
  State<ClaimActivateScreen> createState() => _ClaimActivateScreenState();
}

class _ClaimActivateScreenState extends State<ClaimActivateScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;

  void _activate() async {
    if (_passwordCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal 6 karakter')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final res = await ApiService.claimActivate(
      memberId: widget.memberData['id'],
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );
    setState(() => _isLoading = false);

    if (res['status'] == 200) {
      // Success activation and auto login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      String msg = res['data']['message'] ?? 'Aktvasi gagal';
      if (res['data']['errors'] != null) {
        msg = (res['data']['errors'] as Map).values.first[0];
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Akun Perpus')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Halo, ${widget.memberData['name']}!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  const SizedBox(height: 4),
                  Text('${widget.memberData['type'].toString().toUpperCase()} - ${widget.memberData['nis_nip']}'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Langkah Terakhir',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Buat email dan password untuk login ke aplikasi perpustakaan ke depannya.'),
            const SizedBox(height: 24),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email Baru',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(
                labelText: 'Password (Min 6 Karakter)',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _activate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Aktivasi Akun', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
