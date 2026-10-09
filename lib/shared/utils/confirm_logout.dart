import 'package:flutter/material.dart';
import '../widgets/app_dialog.dart';

Future<bool> confirmLogout(BuildContext context) => showAppConfirmDialog(
  context,
  title: 'Keluar Akun',
  message: 'Yakin ingin keluar dari akun ini?',
  icon: Icons.logout_rounded,
  confirmLabel: 'Ya, Keluar',
  destructive: true,
);
