import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
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

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const _primary = Color(0xFF1A3C2A);
  static const _primaryLight = Color(0xFF2B5A41);
  static const _accent = Color(0xFFD4E8D9);
  static const _surface = Color(0xFFF6F8F7);
  static const _inputBg = Color(0xFFF1F4F2);
  static const _textPrimary = Color(0xFF1A1D1B);
  static const _textSecondary = Color(0xFF6B7770);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    if (_emailCtrl.text.trim().isEmpty) {
      _showSnackBar('Masukkan email Anda', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final res = await ApiService.forgotSendOtp(_emailCtrl.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['status'] == 200) {
      _showSnackBar(res['data']['message'] ?? 'OTP terkirim');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyOtpScreen(email: _emailCtrl.text.trim()),
        ),
      );
    } else {
      _showSnackBar(res['data']['message'] ?? 'Gagal mengirim OTP', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade400 : _primaryLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: _textPrimary,
                        style: IconButton.styleFrom(
                          backgroundColor: _surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Lupa Kata Sandi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),

                        // Icon
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            size: 48,
                            color: _primaryLight,
                          ),
                        ),
                        const SizedBox(height: 28),

                        const Text(
                          'Reset Password',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Masukkan email yang terdaftar.\nKami akan mengirimkan kode OTP\nke email Anda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: _textSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Email field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                fontSize: 16,
                                color: _textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              cursorColor: _primaryLight,
                              decoration: InputDecoration(
                                hintText: 'Masukkan alamat email',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 15,
                                ),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(left: 16, right: 12),
                                  child: Icon(Icons.email_outlined, color: _textSecondary, size: 22),
                                ),
                                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                filled: true,
                                fillColor: _inputBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFE8ECE9), width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: _primaryLight, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Send OTP button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _sendOtp,
                            icon: _isLoading
                                ? const SizedBox.shrink()
                                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            label: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Kirim Kode OTP',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: _primary.withOpacity(0.6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),

                        const Spacer(flex: 3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
