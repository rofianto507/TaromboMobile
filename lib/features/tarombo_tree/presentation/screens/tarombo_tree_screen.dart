import 'package:flutter/material.dart';
import '../../../../shared/widgets/notifikasi_button.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold   = Color(0xFFC8A24A);

/// Placeholder tab "Tarombo" — nanti berisi visualisasi pohon silsilah.
/// Sengaja screen kosong dulu (bukan dihapus dari bottom nav) supaya posisi
/// tab-nya sudah final duluan sebelum fitur pohonnya dibangun.
class TaromboTreeScreen extends StatelessWidget {
  const TaromboTreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tarombo'), actions: const [NotifikasiButton()]),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_tree_outlined, size: 64, color: _kGreen1.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              const Text(
                'Pohon Silsilah',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kGreen1),
              ),
              const SizedBox(height: 8),
              Text(
                'Tampilan visual pohon silsilah keluarga sedang disiapkan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 4),
              const Text('Segera hadir', style: TextStyle(color: _kGold, fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
