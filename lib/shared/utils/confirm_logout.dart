import 'package:flutter/material.dart';

Future<bool> confirmLogout(BuildContext context) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Keluar Akun'),
      content: const Text('Yakin ingin keluar dari akun ini?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, Keluar')),
      ],
    ),
  );
  return confirm == true;
}
