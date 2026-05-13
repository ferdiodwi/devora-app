import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'reset_password_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocuses = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;

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
    for (var c in _otpCtrls) {
      c.dispose();
    }
    for (var f in _otpFocuses) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _otpCtrls.map((c) => c.text).join();

  void _verifyOtp() async {
    final otp = _otpCode;
    if (otp.length != 6) {
      _showSnackBar('Masukkan 6 digit kode OTP', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final res = await ApiService.forgotVerifyOtp(widget.email, otp);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['status'] == 200) {
      final resetToken = res['data']['reset_token'];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            email: widget.email,
            resetToken: resetToken,
          ),
        ),
      );
    } else {
      _showSnackBar(res['data']['message'] ?? 'OTP tidak valid', isError: true);
    }
  }

  void _resendOtp() async {
    setState(() => _isResending = true);
    final res = await ApiService.forgotSendOtp(widget.email);
    if (!mounted) return;
    setState(() => _isResending = false);

    if (res['status'] == 200) {
      _showSnackBar('Kode OTP baru telah dikirim');
      // Clear OTP fields
      for (var c in _otpCtrls) {
        c.clear();
      }
      _otpFocuses[0].requestFocus();
    } else {
      _showSnackBar(res['data']['message'] ?? 'Gagal mengirim ulang', isError: true);
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
                        'Verifikasi OTP',
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),

                        // Icon
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mark_email_read_rounded,
                            size: 48,
                            color: _primaryLight,
                          ),
                        ),
                        const SizedBox(height: 28),

                        const Text(
                          'Cek Email Anda',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Masukkan kode 6 digit yang telah\ndikirim ke ${widget.email}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: _textSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // OTP Fields
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (i) {
                            return Container(
                              width: 48,
                              height: 56,
                              margin: EdgeInsets.only(
                                right: i < 5 ? 8 : 0,
                                left: i == 3 ? 8 : 0,
                              ),
                              child: TextField(
                                controller: _otpCtrls[i],
                                focusNode: _otpFocuses[i],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 6, // allow paste
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                ),
                                cursorColor: _primaryLight,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: _otpCtrls[i].text.isNotEmpty
                                      ? _accent.withOpacity(0.3)
                                      : _inputBg,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _otpCtrls[i].text.isNotEmpty
                                          ? _primaryLight
                                          : const Color(0xFFE8ECE9),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: _primaryLight, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                onChanged: (value) {
                                  // Handle paste: if user pastes full OTP code
                                  if (value.length > 1) {
                                    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                                    for (int j = 0; j < 6; j++) {
                                      _otpCtrls[j].text = j < digits.length ? digits[j] : '';
                                    }
                                    // Focus last filled or last box
                                    final focusIdx = digits.length >= 6 ? 5 : digits.length;
                                    if (focusIdx < 6) {
                                      _otpFocuses[focusIdx].requestFocus();
                                    }
                                    setState(() {});
                                    if (digits.length >= 6) {
                                      _verifyOtp();
                                    }
                                    return;
                                  }

                                  setState(() {}); // update fill color
                                  if (value.isNotEmpty && i < 5) {
                                    _otpFocuses[i + 1].requestFocus();
                                  } else if (value.isEmpty && i > 0) {
                                    _otpFocuses[i - 1].requestFocus();
                                  }
                                  // Auto-verify when all 6 digits entered
                                  if (_otpCode.length == 6) {
                                    _verifyOtp();
                                  }
                                },
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 32),

                        // Verify button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: _primary.withOpacity(0.6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Verifikasi',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Resend OTP
                        GestureDetector(
                          onTap: _isResending ? null : _resendOtp,
                          child: RichText(
                            text: TextSpan(
                              text: 'Tidak menerima kode? ',
                              style: const TextStyle(
                                fontSize: 14,
                                color: _textSecondary,
                              ),
                              children: [
                                TextSpan(
                                  text: _isResending ? 'Mengirim...' : 'Kirim Ulang',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _isResending
                                        ? _textSecondary
                                        : _primaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
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
