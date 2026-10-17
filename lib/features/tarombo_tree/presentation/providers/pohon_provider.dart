import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../klaim/presentation/providers/klaim_provider.dart';
import '../../domain/entities/pohon_node.dart';

/// Override sengaja/manual "pusat" pohon (ganti fokus lewat cari nama, atau
/// tap simpul yang tertutup). null berarti pakai posisi orang.id milik
/// akun sendiri (dari klaimNotifierProvider) sebagai default.
final pohonRootIdProvider = StateProvider<int?>((ref) => null);

enum PohonMode {
  cabang('cabang'),
  radial('radial');

  final String apiValue;
  const PohonMode(this.apiValue);
}

/// Mode 'cabang' (default): ayah + saudara tertutup + keturunan fokus.
/// Mode 'radial': seluruh keturunan leluhur acuan, fokus ditandai selected —
/// lihat get_pohon_data() di backend (models/tarombo_pohon.py).
final pohonModeProvider = StateProvider<PohonMode>((ref) => PohonMode.cabang);

final pohonNotifierProvider = AsyncNotifierProvider<PohonNotifier, PohonNode?>(
  PohonNotifier.new,
);

class PohonNotifier extends AsyncNotifier<PohonNode?> {
  @override
  Future<PohonNode?> build() async {
    final override = ref.watch(pohonRootIdProvider);
    final mode = ref.watch(pohonModeProvider);
    // Sama seperti klaimNotifierProvider: WAJIB nunggu klaim info resolve
    // duluan (bukan cuma baca orang id yang belum tentu ada), supaya pohon
    // otomatis rebuild begitu klaim baru saja disetujui.
    final klaimInfo = await ref.watch(klaimNotifierProvider.future);
    final rootId = override ?? klaimInfo.orang?.id;
    if (rootId == null) return null;

    final api = ref.read(apiClientProvider);
    final json = await api.callKw(
      model: 'tarombo.orang',
      method: 'get_pohon_data',
      args: [rootId, mode.apiValue],
    );
    if (json is! Map || json.isEmpty) return null;
    return PohonNode.fromJson(json.cast<String, dynamic>());
  }

  void pindahFokus(int orangId) {
    ref.read(pohonRootIdProvider.notifier).state = orangId;
  }

  void kembaliKeDiriSendiri() {
    ref.read(pohonRootIdProvider.notifier).state = null;
  }

  void gantiMode(PohonMode mode) {
    ref.read(pohonModeProvider.notifier).state = mode;
  }
}
