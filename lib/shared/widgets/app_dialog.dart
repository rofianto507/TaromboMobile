import 'package:flutter/material.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold = Color(0xFFC8A24A);
const _kRed = Color(0xFFC62828);

/// Dialog konfirmasi bertema Tarombo (pengganti AlertDialog bawaan).
///
/// [destructive] mewarnai ikon & tombol utama merah untuk aksi yang tidak bisa
/// dibatalkan (hapus, keluar). [content] opsional disisipkan di bawah pesan,
/// mis. kolom alasan. Mengembalikan true bila tombol utama ditekan.
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  Widget? content,
  IconData icon = Icons.help_outline_rounded,
  String confirmLabel = 'Ya',
  String cancelLabel = 'Batal',
  bool destructive = false,
}) async {
  final ok = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (ctx, _, _) => _AppDialog(
      title: title,
      message: message,
      content: content,
      icon: icon,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    ),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(curved), child: child),
      );
    },
  );
  return ok == true;
}

class _AppDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final IconData icon;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  const _AppDialog({
    required this.title,
    required this.message,
    required this.content,
    required this.icon,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
  });

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? _kRed : _kGreen1;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pita aksen emas di tepi atas — penanda gaya Tarombo.
              Container(height: 4, color: destructive ? _kRed : _kGold),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.10),
                        border: Border.all(
                          color: (destructive ? _kRed : _kGold).withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                      child: Icon(icon, size: 30, color: accent),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                    if (content != null) ...[
                      const SizedBox(height: 14),
                      content!,
                    ],
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kGreen1,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(cancelLabel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              confirmLabel,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
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
}
