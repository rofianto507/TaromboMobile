import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/registration_provider.dart';

const _kGreen0 = Color(0xFF16261B);
const _kGreen1 = Color(0xFF2E5339);
const _kGreen2 = Color(0xFF3E6B4A);
const _kGold   = Color(0xFFC8A24A);
const _kDark   = Color(0xFF2E5339);

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _password2Ctrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _password2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(registrationProvider.notifier).register(
          nama: _namaCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(registrationProvider);
    final isLoading = regState.status == RegStatus.loading;
    final isSuccess = regState.status == RegStatus.success;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kGreen0, _kGreen1, _kGreen2],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: isSuccess ? _buildSuccess(context) : _buildForm(isLoading),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(bool isLoading) {
    final regState = ref.watch(registrationProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
              onPressed: () => context.pop(),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Daftar Akun',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Setelah daftar, Anda perlu mengklaim identitas\ndi pohon keluarga untuk diverifikasi pengurus.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.60), fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 48, offset: const Offset(0, 20)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [_kGreen1, _kGreen2]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: const Text(
                  'Data Pendaftaran',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.5),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildField(
                        controller: _namaCtrl,
                        label: 'Nama Lengkap',
                        icon: Icons.person_outline_rounded,
                        enabled: !isLoading,
                        action: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _emailCtrl,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        enabled: !isLoading,
                        keyboardType: TextInputType.emailAddress,
                        action: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                            return 'Email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _passwordCtrl,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        enabled: !isLoading,
                        obscure: _obscure,
                        action: TextInputAction.next,
                        suffix: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 20, color: Colors.grey.shade600),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Wajib diisi';
                          if (v.length < 8) return 'Minimal 8 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _password2Ctrl,
                        label: 'Ulangi Password',
                        icon: Icons.lock_outline_rounded,
                        enabled: !isLoading,
                        obscure: _obscure,
                        action: TextInputAction.done,
                        onSubmit: (_) => isLoading ? null : _submit(),
                        validator: (v) => v != _passwordCtrl.text ? 'Password tidak sama' : null,
                      ),
                      if (regState.status == RegStatus.error) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(regState.error ?? '', style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _kGold,
                            foregroundColor: _kGreen1,
                            disabledBackgroundColor: _kGold.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : const Text('Daftar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.pop(),
          child: Text('Sudah punya akun? Login', style: TextStyle(color: _kGold.withValues(alpha: 0.9), fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final login = ref.watch(registrationProvider).login;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.10),
            border: Border.all(color: _kGold.withValues(alpha: 0.5), width: 2),
          ),
          child: const Icon(Icons.check_circle_outline_rounded, size: 44, color: _kGold),
        ),
        const SizedBox(height: 24),
        const Text('Registrasi Berhasil!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Text(
          'Silakan login, lalu klaim identitas Anda\ndi pohon keluarga untuk diverifikasi pengurus.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.70), fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 16),
        if (login != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kGold.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text('Email untuk login:', style: TextStyle(color: Colors.white.withValues(alpha: 0.60), fontSize: 12)),
                const SizedBox(height: 6),
                Text(login, style: const TextStyle(color: _kGold, fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _kGold,
              foregroundColor: _kGreen1,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            onPressed: () {
              ref.read(registrationProvider.notifier).reset();
              context.go('/login');
            },
            child: const Text('Login Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    bool obscure = false,
    ValueChanged<String>? onSubmit,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFE0DED0)),
    );
    const focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: _kGold, width: 2),
    );

    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: action,
      onFieldSubmitted: onSubmit,
      style: const TextStyle(color: _kDark, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 14),
        prefixIcon: Icon(icon, color: _kGold, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFFAF9F5),
        border: border,
        enabledBorder: border,
        focusedBorder: focusBorder,
        errorBorder: border.copyWith(borderSide: const BorderSide(color: Colors.red)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator ?? (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
    );
  }
}
