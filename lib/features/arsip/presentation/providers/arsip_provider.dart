import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/arsip_item.dart';

/// Tambah / hapus arsip milik sendiri tanpa verifikasi pengurus. Dibatasi
/// ir.rule backend: tambah hanya ke profil sendiri (orang.user_id = akun ini),
/// hapus hanya arsip yang diunggah akun ini (create_uid).
class ArsipRepository {
  final Ref ref;
  ArsipRepository(this.ref);

  Future<void> tambah({
    required int orangId,
    List<int> orangIds = const [],
    required String nama,
    required String jenis,
    required String berkasBase64,
    required String berkasNama,
    String? tahunPerkiraan,
    String? sumber,
    String? keterangan,
    bool publik = true,
  }) async {
    await ref
        .read(apiClientProvider)
        .callKw(
          model: 'tarombo.arsip',
          method: 'create',
          args: [
            {
              // Arsip bisa terikat ke banyak anggota; profil sendiri selalu ikut.
              'orang_ids': [
                [
                  6,
                  0,
                  {orangId, ...orangIds}.toList(),
                ],
              ],
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

  /// Mengisi nama anggota terkait (search_read arsip hanya memberi id).
  Future<List<ArsipItem>> isiNamaOrang(List<ArsipItem> items) async {
    final ids = {for (final a in items) ...a.orang.map((o) => o.id)}.toList();
    if (ids.isEmpty) return items;
    try {
      final rows =
          await ref
                  .read(apiClientProvider)
                  .callKw(
                    model: 'tarombo.orang',
                    method: 'search_read',
                    args: [
                      [
                        ['id', 'in', ids],
                      ],
                    ],
                    kwargs: {
                      'fields': ['id', 'name'],
                    },
                  )
              as List;
      final nama = {
        for (final r in rows.cast<Map<String, dynamic>>())
          r['id'] as int: r['name'] as String,
      };
      return [for (final a in items) a.denganNamaOrang(nama)];
    } catch (_) {
      return items;
    }
  }

  Future<void> hapus(int arsipId) async {
    await ref
        .read(apiClientProvider)
        .callKw(
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
