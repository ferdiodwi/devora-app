import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../widgets/custom_text_field.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Notification prefs
  bool _notifPinjaman = true;
  bool _notifDenda = true;
  bool _notifJatuhTempo = true;

  @override
  void initState() {
    super.initState();
    _loadNotifPrefs();
  }

  Future<void> _loadNotifPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifPinjaman = prefs.getBool('notif_pinjaman') ?? true;
      _notifDenda = prefs.getBool('notif_denda') ?? true;
      _notifJatuhTempo = prefs.getBool('notif_jatuh_tempo') ?? true;
    });
  }

  Future<void> _saveNotifPref(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
  }

  // ───────────────────────────────────────────────────────────
  // BOTTOM SHEET: Ganti Password
  // ───────────────────────────────────────────────────────────
  void _showChangePasswordSheet() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? currentErr, newErr, confirmErr;
    bool isLoading = false;
    bool obscureCurrent = true, obscureNew = true, obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            Future<void> submit() async {
              bool valid = true;
              setSheet(() {
                currentErr = null;
                newErr = null;
                confirmErr = null;
                if (currentCtrl.text.isEmpty) {
                  currentErr = 'Wajib diisi';
                  valid = false;
                }
                if (newCtrl.text.length < 6) {
                  newErr = 'Minimal 6 karakter';
                  valid = false;
                }
                if (confirmCtrl.text != newCtrl.text) {
                  confirmErr = 'Password tidak cocok';
                  valid = false;
                }
              });
              if (!valid) return;

              setSheet(() => isLoading = true);
              final res = await ApiService.changePassword(
                currentPassword: currentCtrl.text,
                newPassword: newCtrl.text,
              );
              setSheet(() => isLoading = false);

              if (!ctx.mounted) return;
              if (res['status'] == 200) {
                Navigator.pop(ctx);
                _showSuccess('Password berhasil diubah!');
              } else {
                final data = res['data'];
                if (data['errors'] != null &&
                    data['errors']['current_password'] != null) {
                  setSheet(
                    () => currentErr = data['errors']['current_password'][0],
                  );
                } else {
                  setSheet(
                    () => currentErr = data['message'] ?? 'Terjadi kesalahan',
                  );
                }
              }
            }

            return _buildBottomSheet(
              title: 'Ganti Password',
              icon: Icons.lock_outline,
              isLoading: isLoading,
              onSubmit: submit,
              submitLabel: 'Simpan Password',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PasswordFieldSheet(
                    label: 'PASSWORD LAMA',
                    hint: 'Masukkan password saat ini',
                    controller: currentCtrl,
                    errorText: currentErr,
                    obscure: obscureCurrent,
                    onToggle: () =>
                        setSheet(() => obscureCurrent = !obscureCurrent),
                    onChanged: () => setSheet(() => currentErr = null),
                  ),
                  const SizedBox(height: 14),
                  _PasswordFieldSheet(
                    label: 'PASSWORD BARU',
                    hint: 'Min. 6 karakter',
                    controller: newCtrl,
                    errorText: newErr,
                    obscure: obscureNew,
                    onToggle: () => setSheet(() => obscureNew = !obscureNew),
                    onChanged: () => setSheet(() => newErr = null),
                  ),
                  const SizedBox(height: 14),
                  _PasswordFieldSheet(
                    label: 'KONFIRMASI PASSWORD BARU',
                    hint: 'Ulangi password baru',
                    controller: confirmCtrl,
                    errorText: confirmErr,
                    obscure: obscureConfirm,
                    onToggle: () =>
                        setSheet(() => obscureConfirm = !obscureConfirm),
                    onChanged: () => setSheet(() => confirmErr = null),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showForgotPasswordSheet();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Lupa Password Lama?',
                        style: TextStyle(
                          color: Color(0xFF2B5A41),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────
  // BOTTOM SHEET: Lupa Password (OTP)
  // ───────────────────────────────────────────────────────────
  void _showForgotPasswordSheet() {
    bool isOtpSent = false;
    bool isOtpVerified = false;
    bool isLoading = false;

    String? accountEmail;
    String? resetToken;

    final otpCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    String? otpErr, newErr, confirmErr, generalErr;
    bool obscureNew = true, obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            Future<String?> getLoggedInEmail() async {
              final profileRes = await ApiService.getProfile();

              if (profileRes['status'] != 200) {
                return null;
              }

              final data = profileRes['data'];

              if (data['user'] != null && data['user']['email'] != null) {
                return data['user']['email'].toString();
              }

              if (data['email'] != null) {
                return data['email'].toString();
              }

              return null;
            }

            Future<void> sendOtp() async {
              setSheet(() {
                isLoading = true;
                generalErr = null;
              });

              accountEmail ??= await getLoggedInEmail();

              if (accountEmail == null || accountEmail!.isEmpty) {
                setSheet(() {
                  isLoading = false;
                  generalErr =
                      'Gagal mengambil email akun. Silakan login ulang.';
                });
                return;
              }

              final res = await ApiService.forgotSendOtp(accountEmail!);

              setSheet(() => isLoading = false);

              if (res['status'] == 200) {
                setSheet(() {
                  isOtpSent = true;
                  generalErr = null;
                });

                _showSuccess(
                  res['data']['message'] ??
                      'OTP telah dikirim ke WhatsApp yang terdaftar.',
                );
              } else {
                setSheet(() {
                  generalErr =
                      res['data']['message'] ??
                      'Gagal mengirim OTP ke WhatsApp.';
                });
              }
            }

            Future<void> verifyOtp() async {
              bool valid = true;

              setSheet(() {
                otpErr = null;
                generalErr = null;

                if (otpCtrl.text.trim().isEmpty) {
                  otpErr = 'Wajib diisi';
                  valid = false;
                } else if (otpCtrl.text.trim().length != 6) {
                  otpErr = 'OTP harus 6 digit';
                  valid = false;
                }
              });

              if (!valid) return;

              setSheet(() => isLoading = true);

              final res = await ApiService.forgotVerifyOtp(
                accountEmail!,
                otpCtrl.text.trim(),
              );

              setSheet(() => isLoading = false);

              if (res['status'] == 200) {
                final data = res['data'];

                setSheet(() {
                  isOtpVerified = true;
                  resetToken = data['reset_token'];
                  generalErr = null;
                });

                _showSuccess('OTP berhasil diverifikasi.');
              } else {
                setSheet(() {
                  generalErr =
                      res['data']['message'] ?? 'Kode OTP tidak valid.';
                });
              }
            }

            Future<void> resetPassword() async {
              bool valid = true;

              setSheet(() {
                newErr = null;
                confirmErr = null;
                generalErr = null;

                if (newCtrl.text.length < 6) {
                  newErr = 'Minimal 6 karakter';
                  valid = false;
                }

                if (confirmCtrl.text != newCtrl.text) {
                  confirmErr = 'Password tidak cocok';
                  valid = false;
                }

                if (resetToken == null || resetToken!.isEmpty) {
                  generalErr = 'Token reset tidak valid. Verifikasi OTP ulang.';
                  valid = false;
                }
              });

              if (!valid) return;

              setSheet(() => isLoading = true);

              final res = await ApiService.forgotResetPassword(
                accountEmail!,
                resetToken!,
                newCtrl.text,
              );

              setSheet(() => isLoading = false);

              if (!ctx.mounted) return;

              if (res['status'] == 200) {
                Navigator.pop(ctx);
                _showSuccess('Password berhasil direset!');
              } else {
                setSheet(() {
                  generalErr =
                      res['data']['message'] ?? 'Gagal mereset password.';
                });
              }
            }

            Future<void> submit() async {
              if (!isOtpSent) {
                await sendOtp();
                return;
              }

              if (!isOtpVerified) {
                await verifyOtp();
                return;
              }

              await resetPassword();
            }

            String submitLabel;
            if (!isOtpSent) {
              submitLabel = 'Kirim OTP WhatsApp';
            } else if (!isOtpVerified) {
              submitLabel = 'Verifikasi OTP';
            } else {
              submitLabel = 'Reset Password';
            }

            return _buildBottomSheet(
              title: 'Lupa Password',
              icon: Icons.lock_reset,
              isLoading: isLoading,
              onSubmit: submit,
              submitLabel: submitLabel,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (generalErr != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        generalErr!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (!isOtpSent)
                    const Text(
                      'Kami akan mengirimkan 6 digit kode OTP ke WhatsApp yang terdaftar pada akun Anda.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),

                  if (isOtpSent && !isOtpVerified) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5EE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBEAD7)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_rounded,
                            color: Color(0xFF2B5A41),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              accountEmail == null
                                  ? 'OTP dikirim ke WhatsApp yang terdaftar.'
                                  : 'OTP dikirim ke WhatsApp akun: $accountEmail',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF2B5A41),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'KODE OTP',
                      hint: 'Masukkan 6 digit OTP',
                      controller: otpCtrl,
                      prefixIcon: Icons.vpn_key_outlined,
                      errorText: otpErr,
                      keyboardType: TextInputType.number,
                      onChanged: () => setSheet(() => otpErr = null),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading ? null : sendOtp,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Kirim ulang OTP',
                          style: TextStyle(
                            color: Color(0xFF2B5A41),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (isOtpVerified) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5EE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBEAD7)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF2B5A41),
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'OTP berhasil diverifikasi. Silakan buat password baru.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF2B5A41),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _PasswordFieldSheet(
                      label: 'PASSWORD BARU',
                      hint: 'Min. 6 karakter',
                      controller: newCtrl,
                      errorText: newErr,
                      obscure: obscureNew,
                      onToggle: () => setSheet(() => obscureNew = !obscureNew),
                      onChanged: () => setSheet(() => newErr = null),
                    ),
                    const SizedBox(height: 14),
                    _PasswordFieldSheet(
                      label: 'KONFIRMASI PASSWORD BARU',
                      hint: 'Ulangi password baru',
                      controller: confirmCtrl,
                      errorText: confirmErr,
                      obscure: obscureConfirm,
                      onToggle: () =>
                          setSheet(() => obscureConfirm = !obscureConfirm),
                      onChanged: () => setSheet(() => confirmErr = null),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────
  // BOTTOM SHEET: Edit Nomor HP
  // ───────────────────────────────────────────────────────────
  void _showEditPhoneSheet() {
    final phoneCtrl = TextEditingController();
    String? phoneErr;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            Future<void> submit() async {
              setSheet(() => phoneErr = null);
              if (phoneCtrl.text.trim().isEmpty) {
                setSheet(() => phoneErr = 'Nomor HP tidak boleh kosong');
                return;
              }
              if (phoneCtrl.text.trim().length < 10) {
                setSheet(() => phoneErr = 'Nomor HP minimal 10 digit');
                return;
              }

              setSheet(() => isLoading = true);
              final res = await ApiService.updatePhone(phoneCtrl.text.trim());
              setSheet(() => isLoading = false);

              if (!ctx.mounted) return;
              if (res['status'] == 200) {
                Navigator.pop(ctx);
                _showSuccess('Nomor HP berhasil diperbarui!');
              } else {
                setSheet(
                  () =>
                      phoneErr = res['data']['message'] ?? 'Terjadi kesalahan',
                );
              }
            }

            return _buildBottomSheet(
              title: 'Edit Nomor HP',
              icon: Icons.phone_outlined,
              isLoading: isLoading,
              onSubmit: submit,
              submitLabel: 'Simpan Nomor HP',
              content: CustomTextField(
                label: 'NOMOR HP BARU',
                hint: '08xxxxxxxxxx',
                controller: phoneCtrl,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                errorText: phoneErr,
                onChanged: () => setSheet(() => phoneErr = null),
              ),
            );
          },
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────
  // Helper: Generic bottom sheet container
  // ───────────────────────────────────────────────────────────
  Widget _buildBottomSheet({
    required String title,
    required IconData icon,
    required bool isLoading,
    required VoidCallback onSubmit,
    required String submitLabel,
    required Widget content,
  }) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF2B5A41), size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          content,
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(submitLabel),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: const Color(0xFF2B5A41),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // BUILD
  // ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAF8),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: Color(0xFF2B5A41),
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pengaturan Akun',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1E1E),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ─── Keamanan ────────────────────────────
          _sectionLabel('KEAMANAN AKUN'),
          const SizedBox(height: 10),
          _card(
            children: [
              _settingItem(
                icon: Icons.lock_outline,
                iconBg: const Color(0xFFE8F5EE),
                iconColor: const Color(0xFF2B5A41),
                title: 'Ganti Password',
                subtitle: 'Ubah kata sandi akun Anda',
                onTap: _showChangePasswordSheet,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Informasi Akun ────────────────────────────
          _sectionLabel('INFORMASI AKUN'),
          const SizedBox(height: 10),
          _card(
            children: [
              _settingItem(
                icon: Icons.phone_outlined,
                iconBg: const Color(0xFFE3F2FD),
                iconColor: const Color(0xFF1565C0),
                title: 'Edit Nomor HP',
                subtitle: 'Perbarui nomor handphone Anda',
                onTap: _showEditPhoneSheet,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Notifikasi ────────────────────────────
          _sectionLabel('PREFERENSI NOTIFIKASI'),
          const SizedBox(height: 10),
          _card(
            children: [
              _toggleItem(
                icon: Icons.book_outlined,
                iconBg: const Color(0xFFFFF8E1),
                iconColor: const Color(0xFFF9A825),
                title: 'Notifikasi Peminjaman',
                subtitle: 'Konfirmasi & update peminjaman',
                value: _notifPinjaman,
                onChanged: (v) {
                  setState(() => _notifPinjaman = v);
                  _saveNotifPref('notif_pinjaman', v);
                },
              ),
              _divider(),
              _toggleItem(
                icon: Icons.warning_amber_outlined,
                iconBg: const Color(0xFFFCE4EC),
                iconColor: const Color(0xFFC62828),
                title: 'Notifikasi Denda',
                subtitle: 'Pemberitahuan denda buku',
                value: _notifDenda,
                onChanged: (v) {
                  setState(() => _notifDenda = v);
                  _saveNotifPref('notif_denda', v);
                },
              ),
              _divider(),
              _toggleItem(
                icon: Icons.access_time_outlined,
                iconBg: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF2E7D32),
                title: 'Jatuh Tempo',
                subtitle: 'Pengingat buku mendekati jatuh tempo',
                value: _notifJatuhTempo,
                onChanged: (v) {
                  setState(() => _notifJatuhTempo = v);
                  _saveNotifPref('notif_jatuh_tempo', v);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Tentang ────────────────────────────
          _sectionLabel('TENTANG APLIKASI'),
          const SizedBox(height: 10),
          _card(
            children: [
              _settingItem(
                icon: Icons.info_outline,
                iconBg: const Color(0xFFEDE7F6),
                iconColor: const Color(0xFF4527A0),
                title: 'Versi Aplikasi',
                subtitle: 'v1.0.0',
                showArrow: false,
                onTap: null,
              ),
              _divider(),
              _settingItem(
                icon: Icons.privacy_tip_outlined,
                iconBg: const Color(0xFFE0F2F1),
                iconColor: const Color(0xFF00695C),
                title: 'Kebijakan Privasi',
                subtitle: 'Baca kebijakan privasi kami',
                onTap: () {
                  // Bisa buka WebView atau dialog statis
                  _showPrivacyDialog();
                },
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─── Widgets Builder ─────────────────────────────────────────

  Widget _sectionLabel(String label) => Text(
    label,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: Colors.grey,
      letterSpacing: 0.8,
    ),
  );

  Widget _card({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(children: children),
  );

  Widget _divider() =>
      Divider(height: 1, thickness: 1, indent: 60, color: Colors.grey.shade100);

  Widget _settingItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool showArrow = true,
    VoidCallback? onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (showArrow) Icon(Icons.chevron_right, color: Colors.grey.shade300),
        ],
      ),
    ),
  );

  Widget _toggleItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: const Color(0xFF2B5A41),
          activeThumbColor: Colors.white,
        ),
      ],
    ),
  );

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Kebijakan Privasi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const Text(
          'Aplikasi Perpustakaan Digital SMA Negeri 4 Jember mengumpulkan data '
          'akun dan aktivitas peminjaman buku untuk memberikan layanan perpustakaan '
          'yang lebih baik. Data tidak akan dibagikan kepada pihak ketiga.\n\n'
          'Dengan menggunakan aplikasi ini, Anda menyetujui kebijakan privasi kami.',
          style: TextStyle(fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Mengerti',
              style: TextStyle(
                color: Color(0xFF2B5A41),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper widget untuk password field di bottom sheet ──────────────────────
class _PasswordFieldSheet extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? errorText;
  final bool obscure;
  final VoidCallback onToggle;
  final VoidCallback onChanged;

  const _PasswordFieldSheet({
    required this.label,
    required this.hint,
    required this.controller,
    required this.errorText,
    required this.obscure,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: label,
      hint: hint,
      controller: controller,
      prefixIcon: Icons.lock_outline,
      obscureText: obscure,
      errorText: errorText,
      onChanged: onChanged,
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: Colors.grey,
          size: 20,
        ),
        onPressed: onToggle,
      ),
    );
  }
}
