import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../klaim/presentation/providers/klaim_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/profil_saya.dart';

/// Profil milik akun yang login + kelengkapannya. null bila akun belum
/// tertaut ke data anggota (klaim belum disetujui).
final profilSayaProvider = FutureProvider.autoDispose<ProfilSaya?>((ref) async {
  // Bergantung pada status klaim: begitu klaim disetujui/dicabut, profil ini
  // ikut dimuat ulang, dan tidak memanggil API selagi belum login.
  final klaim = await ref.watch(klaimNotifierProvider.future);
  if (klaim.orang == null) return null;
  final json = await ref
      .read(apiClientProvider)
      .callKw(model: 'tarombo.orang', method: 'get_profil_saya', args: const []);
  if (json is! Map) return null;
  return ProfilSaya.fromJson(json.cast<String, dynamic>());
});

/// Menulis data profil sendiri (foto, tanggal lahir, domisili) langsung, tanpa
/// usulan. Backend hanya menerima field yang masuk daftar putihnya dan hanya
/// untuk record milik akun ini.
class ProfilSayaRepository {
  final Ref ref;
  ProfilSayaRepository(this.ref);

  Future<void> simpan(int orangId, Map<String, dynamic> vals) async {
    await ref.read(apiClientProvider).callKw(
      model: 'tarombo.orang',
      method: 'update_profil_saya',
      args: [vals],
    );
    if (vals.containsKey('foto')) {
      // Foto diambil dari URL yang sama (/web/image/...), jadi tembolok gambar
      // harus dibuang supaya avatar memuat foto yang baru.
      await CachedNetworkImage.evictFromCache(
        '${AppConfig.baseUrl}/web/image/tarombo.orang/$orangId/foto',
      );
    }
    ref.invalidate(profilSayaProvider);
    ref.invalidate(profileDetailProvider(orangId));
  }
}

final profilSayaRepositoryProvider = Provider<ProfilSayaRepository>(
  (ref) => ProfilSayaRepository(ref),
);
