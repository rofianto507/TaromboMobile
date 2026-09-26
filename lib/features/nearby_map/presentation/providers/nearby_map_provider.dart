import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../klaim/presentation/providers/klaim_provider.dart';
import '../../domain/entities/kerabat_lokasi.dart';

final kerabatLokasiProvider = FutureProvider.autoDispose<List<KerabatLokasi>>((ref) async {
  final api = ref.read(apiClientProvider);
  final rows = await api.callKw(model: 'tarombo.orang', method: 'get_lokasi_kerabat', args: const []) as List;
  return rows.cast<Map<String, dynamic>>().map(KerabatLokasi.fromJson).toList();
});

final berbagiLokasiServiceProvider = Provider((ref) => BerbagiLokasiService(ref));

class BerbagiLokasiService {
  final Ref ref;
  BerbagiLokasiService(this.ref);

  Future<void> aktifkan(double lat, double lng) async {
    final api = ref.read(apiClientProvider);
    await api.callKw(model: 'tarombo.orang', method: 'set_berbagi_lokasi', args: [true], kwargs: {'lat': lat, 'lng': lng});
    ref.invalidate(kerabatLokasiProvider);
    ref.invalidate(klaimNotifierProvider);
  }

  Future<void> nonaktifkan() async {
    final api = ref.read(apiClientProvider);
    await api.callKw(model: 'tarombo.orang', method: 'set_berbagi_lokasi', args: [false]);
    ref.invalidate(kerabatLokasiProvider);
    ref.invalidate(klaimNotifierProvider);
  }
}
