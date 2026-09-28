import 'package:flutter/material.dart';

const _kGreen1 = Color(0xFF2E5339);

/// Placeholder — push notification (topik, izin, dsb.) dibahas & dibangun
/// menyusul terpisah. Ikon lonceng di Beranda sudah ditaruh duluan supaya
/// posisinya final sebelum isinya ada.
class NotifikasiScreen extends StatelessWidget {
  const NotifikasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none_rounded, size: 64, color: _kGreen1.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text('Belum ada notifikasi', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
