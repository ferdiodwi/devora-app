import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String resetToken;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.resetToken,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

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
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _resetPassword() async {
    if (_passwordCtrl.text.trim().isEmpty || _confirmCtrl.text.trim().isEmpty) {
      _showSnackBar('Semua kolom harus diisi', isError: true);
      return;
    }

    if (_passwordCtrl.text.length < 6) {
      _showSnackBar('Password minimal 6 karakter', isError: true);
      return;
    }

    if (_passwordCtrl.text != _confirmCtrl.text) {
      _showSnackBar('Password dan konfirmasi tidak sama', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final res = await ApiService.forgotResetPassword(
      widget.email,
      widget.resetToken,
      _passwordCtrl.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['status'] == 200) {
      // Show success dialog then go back to login
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 48,
                  color: _primaryLight,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Password Diperbarui!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Silakan login dengan\npassword baru Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    // Pop all the way back to login
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Kembali ke Login',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      _showSnackBar(res['data']['message'] ?? 'Gagal reset password', isError: true);
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(
            fontSize: 16,
            color: _textPrimary,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: _primaryLight,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w400,
              fontSize: 15,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16, right: 12),
              child: Icon(Icons.lock_outline_rounded, color: _textSecondary, size: 22),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: _textSecondary,
                  size: 22,
                ),
                onPressed: onToggle,
              ),
            ),
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
                      const SizedBox(width: 48), // no back button on final step
                      const Spacer(),
                      Text(
                        'Password Baru',
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),

                        // Icon
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              size: 48,
                              color: _primaryLight,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        const Text(
                          'Buat Password Baru',
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
                          'Password baru harus berbeda\ndari password sebelumnya.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: _textSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Password fields
                        _buildPasswordField(
                          controller: _passwordCtrl,
                          label: 'Password Baru',
                          hint: 'Minimal 6 karakter',
                          obscure: _obscurePassword,
                          onToggle: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        const SizedBox(height: 20),
                        _buildPasswordField(
                          controller: _confirmCtrl,
                          label: 'Konfirmasi Password',
                          hint: 'Ketik ulang password baru',
                          obscure: _obscureConfirm,
                          onToggle: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        const SizedBox(height: 32),

                        // Reset button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _resetPassword,
                            icon: _isLoading
                                ? const SizedBox.shrink()
                                : const Icon(Icons.check_circle_outline_rounded,
                                    color: Colors.white, size: 22),
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
                                    'Perbarui Password',
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
