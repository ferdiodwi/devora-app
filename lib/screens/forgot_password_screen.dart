import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../widgets/custom_text_field.dart';
import 'verify_otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  String? _emailError;
  String? _generalError;

  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _clearErrors() {
    if (_emailError != null || _generalError != null) {
      setState(() {
        _emailError = null;
        _generalError = null;
      });
    }
  }

  void _sendOtp() async {
    _clearErrors();
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _emailError = 'Email tidak boleh kosong');
      _shakeController.forward(from: 0);
      return;
    }

    setState(() => _isLoading = true);
    final res = await ApiService.forgotSendOtp(_emailCtrl.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['status'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['data']['message'] ?? 'OTP terkirim'),
          backgroundColor: const Color(0xFF2B5A41),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyOtpScreen(email: _emailCtrl.text.trim()),
        ),
      );
    } else {
      setState(() {
        _generalError = res['data']['message'] ?? 'Gagal mengirim OTP';
      });
      _shakeController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // ─── GREEN HEADER BACKGROUND ─────────────────────────
            Container(
              height: size.height * 0.35,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Lupa Kata\nSandi?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Kami akan mengirimkan kode OTP ke WhatsApp yang terdaftar.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── FLOATING CARD ─────────────────────────────
            Padding(
              padding: EdgeInsets.only(
                top: size.height * 0.28,
                left: 20,
                right: 20,
                bottom: 40,
              ),
              child: AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      _shakeController.isAnimating
                          ? 10 * ((_shakeController.value * 5) % 2 < 1 ? 1 : -1)
                          : 0,
                      0,
                    ),
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2B5A41).withValues(alpha: 0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Icon badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F1EC),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF2B5A41), size: 36),
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_generalError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFCDD2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFE53935), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _generalError!,
                                  style: const TextStyle(
                                      color: Color(0xFFE53935),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Email field
                      CustomTextField(
                        label: 'Alamat Email',
                        hint: 'Masukkan email yang terdaftar',
                        controller: _emailCtrl,
                        prefixIcon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                        onChanged: _clearErrors,
                      ),
                      const SizedBox(height: 32),

                      // Send OTP button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B5A41),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Kirim Kode OTP',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                  SizedBox(width: 8),
                                  Icon(Icons.send_rounded, size: 20),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
