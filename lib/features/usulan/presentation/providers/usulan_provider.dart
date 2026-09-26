import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/utils/odoo_json.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/usulan_ringkas.dart';

final usulanListProvider = FutureProvider.autoDispose<List<UsulanRingkas>>((ref) async {
  final api = ref.read(apiClientProvider);
  final rows = await api.callKw(
    model: 'tarombo.usulan',
    method: 'search_read',
    // ir.rule sudah membatasi anggota hanya melihat usulan milik sendiri.
    args: [[]],
    kwargs: {
      'fields': ['name', 'jenis', 'state', 'tanggal_ajukan', 'orang_id', 'ayah_id', 'alasan_tolak'],
      'order': 'id desc',
    },
  ) as List;

  return rows.cast<Map<String, dynamic>>().map((r) {
    final jenis = r['jenis'] as String;
    final target = jenis == 'tambah' ? r['ayah_id'] : r['orang_id'];
    return UsulanRingkas(
      id: r['id'] as int,
      name: r['name'] as String,
      jenis: jenis,
      state: usulanStateFromServer(r['state'] as String),
      targetName: (target is List && target.length > 1) ? target[1] as String : null,
      tanggalAjukan: asOdooString(r['tanggal_ajukan']),
      alasanTolak: asOdooString(r['alasan_tolak']),
    );
  }).toList();
});

final usulanSubmitProvider = Provider((ref) => UsulanSubmitService(ref));

class UsulanSubmitService {
  final Ref ref;
  UsulanSubmitService(this.ref);

  Future<void> submitTambah({
    required String nama,
    required String jenisKelamin,
    required int ayahId,
    required int punguanId,
    required String sumberKet,
    String? catatan,
    String? fotoBase64,
  }) async {
    final api = ref.read(apiClientProvider);
    final id = await api.callKw(
      model: 'tarombo.usulan',
      method: 'create',
      args: [
        {
          'jenis': 'tambah',
          'ayah_id': ayahId,
          'punguan_id': punguanId,
          'usul_nama': nama,
          'usul_jenis_kelamin': jenisKelamin,
          'sumber_ket': sumberKet,
          if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
          'usul_foto': ?fotoBase64,
        }
      ],
    );
    await api.callKw(model: 'tarombo.usulan', method: 'action_ajukan', args: [
      [id]
    ]);
    ref.invalidate(usulanListProvider);
  }

  Future<void> submitEdit({
    required String jenis, // 'koreksi' atau 'lengkapi'
    required int orangId,
    required int punguanId,
    required String sumberKet,
    String? usulNama,
    String? usulJenisKelamin,
    String? usulMasihHidup,
    int? usulUrutan,
    String? usulSuamiNama,
    int? usulSuamiMargaId,
    String? catatan,
    String? fotoBase64,
  }) async {
    final api = ref.read(apiClientProvider);
    final id = await api.callKw(
      model: 'tarombo.usulan',
      method: 'create',
      args: [
        {
          'jenis': jenis,
          'orang_id': orangId,
          'punguan_id': punguanId,
          'sumber_ket': sumberKet,
          if (usulNama != null && usulNama.isNotEmpty) 'usul_nama': usulNama,
          'usul_jenis_kelamin': ?usulJenisKelamin,
          'usul_masih_hidup': ?usulMasihHidup,
          'usul_urutan': ?usulUrutan,
          if (usulSuamiNama != null && usulSuamiNama.isNotEmpty) 'usul_suami_nama': usulSuamiNama,
          'usul_suami_marga_id': ?usulSuamiMargaId,
          if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
          'usul_foto': ?fotoBase64,
        }
      ],
    );
    await api.callKw(model: 'tarombo.usulan', method: 'action_ajukan', args: [
      [id]
    ]);
    ref.invalidate(usulanListProvider);
  }
}
