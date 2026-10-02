import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/exceptions.dart';
import '../providers/auth_provider.dart';

const _kGreen0 = Color(0xFF16261B);
const _kGreen1 = Color(0xFF2E5339);
const _kGreen2 = Color(0xFF3E6B4A);
const _kGold = Color(0xFFC8A24A);
const _kDark = Color(0xFF2E5339);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_clearError);
    _passwordCtrl.addListener(_clearError);
  }

  void _clearError() {
    if (_errorMsg != null) setState(() => _errorMsg = null);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMsg = null);
    await ref
        .read(authNotifierProvider.notifier)
        .login(username: _emailCtrl.text.trim(), password: _passwordCtrl.text);
    if (!mounted) return;
    ref
        .read(authNotifierProvider)
        .whenOrNull(
          error: (e, _) {
            final msg = e is AuthException
                ? e.message
                : 'Terjadi kesalahan koneksi.';
            setState(() => _errorMsg = msg);
          },
        );
  }

  Future<void> _submitGoogle() async {
    setState(() => _errorMsg = null);
    await ref.read(authNotifierProvider.notifier).loginWithGoogle();
    if (!mounted) return;
    ref
        .read(authNotifierProvider)
        .whenOrNull(
          error: (e, _) {
            final msg = e is AuthException
                ? e.message
                : 'Terjadi kesalahan koneksi.';
            setState(() => _errorMsg = msg);
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.6,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(26),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_kGreen0, _kGreen1, _kGreen2],
                        stops: [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                  // Foto rumah adat ditenggelamkan ke corak hijau (bukan
                  // ditumpuk sebagai foto biasa) — di-tint penuh ke warna
                  // hijau (BlendMode.color pertahankan terang-gelapnya saja)
                  // lalu opacity rendah, supaya menyatu sebagai tekstur
                  // latar, bukan foto yang bersaing dengan konten di atasnya.
                  Opacity(
                    opacity: 0.3,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        _kGreen2,
                        BlendMode.color,
                      ),
                      child: Image.asset(
                        'assets/images/rumah.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: _kGold, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 24,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_tree_rounded,
                          size: 46,
                          color: _kGreen1,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'TAROMBO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 1,
                              color: _kGold.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.star, color: _kGold, size: 10),
                            const SizedBox(width: 8),
                            Container(
                              width: 40,
                              height: 1,
                              color: _kGold.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Silsilah Marga Silaen',
                        style: TextStyle(
                          color: Color(0xFFD8E5DC),
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 36),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 48,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                24,
                                24,
                                28,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildField(
                                      controller: _emailCtrl,
                                      label: 'Email',
                                      icon: Icons.email_outlined,
                                      enabled: !isLoading,
                                      keyboardType: TextInputType.emailAddress,
                                      action: TextInputAction.next,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildField(
                                      controller: _passwordCtrl,
                                      label: 'Password',
                                      icon: Icons.lock_outline_rounded,
                                      enabled: !isLoading,
                                      obscure: _obscure,
                                      action: TextInputAction.done,
                                      onSubmit: (_) =>
                                          isLoading ? null : _submit(),
                                      suffix: IconButton(
                                        icon: Icon(
                                          _obscure
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 20,
                                          color: Colors.grey.shade600,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscure = !_obscure,
                                        ),
                                      ),
                                    ),
                                    if (_errorMsg != null) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          border: Border.all(
                                            color: Colors.red.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              color: Colors.red.shade700,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _errorMsg!,
                                                style: TextStyle(
                                                  color: Colors.red.shade800,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 28),
                                    SizedBox(
                                      height: 50,
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: _kGold,
                                          foregroundColor: _kGreen1,
                                          disabledBackgroundColor: _kGold
                                              .withValues(alpha: 0.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: 2,
                                        ),
                                        onPressed: isLoading ? null : _submit,
                                        child: isLoading
                                            ? const SizedBox(
                                                height: 22,
                                                width: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Text(
                                                'Masuk',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: Text(
                                            'atau',
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      height: 50,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _kDark,
                                          side: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        onPressed: isLoading
                                            ? null
                                            : _submitGoogle,
                                        icon: Image.asset(
                                          'assets/images/google_logo.png',
                                          width: 20,
                                          height: 20,
                                        ),
                                        label: const Text(
                                          'Masuk dengan Google',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
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
                        onPressed: () => context.push('/register'),
                        child: Text(
                          'Belum punya akun? Daftar',
                          style: TextStyle(
                            color: _kDark.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    ValueChanged<String>? onSubmit,
    Widget? suffix,
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
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
    );
  }
}
