import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

/// Tambah / hapus arsip milik sendiri tanpa verifikasi pengurus. Dibatasi
/// ir.rule backend: tambah hanya ke profil sendiri (orang.user_id = akun ini),
/// hapus hanya arsip yang diunggah akun ini (create_uid).
class ArsipRepository {
  final Ref ref;
  ArsipRepository(this.ref);

  Future<void> tambah({
    required int orangId,
    required String nama,
    required String jenis,
    required String berkasBase64,
    required String berkasNama,
    String? tahunPerkiraan,
    String? sumber,
    String? keterangan,
    bool publik = true,
  }) async {
    await ref.read(apiClientProvider).callKw(
      model: 'tarombo.arsip',
      method: 'create',
      args: [
        {
          'orang_id': orangId,
          'name': nama,
          'jenis': jenis,
          'berkas': berkasBase64,
          'berkas_nama': berkasNama,
          if (tahunPerkiraan != null && tahunPerkiraan.isNotEmpty)
            'tahun_perkiraan': tahunPerkiraan,
          if (sumber != null && sumber.isNotEmpty) 'sumber': sumber,
          if (keterangan != null && keterangan.isNotEmpty)
            'keterangan': keterangan,
          'publik': publik,
        },
      ],
    );
    ref.invalidate(profileDetailProvider(orangId));
  }

  Future<void> hapus(int arsipId) async {
    await ref.read(apiClientProvider).callKw(
      model: 'tarombo.arsip',
      method: 'unlink',
      args: [
        [arsipId],
      ],
    );
  }
}

final arsipRepositoryProvider = Provider<ArsipRepository>(
  (ref) => ArsipRepository(ref),
);
