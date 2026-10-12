import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/utils/odoo_json.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/usulan_detail.dart';
import '../../domain/entities/usulan_ringkas.dart';

final usulanListProvider = FutureProvider.autoDispose<List<UsulanRingkas>>((
  ref,
) async {
  final api = ref.read(apiClientProvider);
  final rows =
      await api.callKw(
            model: 'tarombo.usulan',
            method: 'search_read',
            // ir.rule sudah membatasi anggota hanya melihat usulan milik sendiri.
            // ('active','in',[True,False]) WAJIB eksplisit di sini — action_tolak()
            // set active=False pada usulan yang ditolak, dan Odoo otomatis
            // menyembunyikan record active=False dari search manapun kecuali domain
            // bilang sebaliknya. Tanpa ini, usulan ditolak hilang total dari daftar.
            args: [
              [
                [
                  'active',
                  'in',
                  [true, false],
                ],
              ],
            ],
            kwargs: {
              'fields': [
                'name',
                'jenis',
                'state',
                'tanggal_ajukan',
                'orang_id',
                'ayah_id',
                'alasan_tolak',
              ],
              'order': 'id desc',
            },
          )
          as List;

  return rows.cast<Map<String, dynamic>>().map((r) {
    final jenis = r['jenis'] as String;
    final target = jenis == 'tambah' ? r['ayah_id'] : r['orang_id'];
    return UsulanRingkas(
      id: r['id'] as int,
      name: r['name'] as String,
      jenis: jenis,
      state: usulanStateFromServer(r['state'] as String),
      targetName: (target is List && target.length > 1)
          ? target[1] as String
          : null,
      tanggalAjukan: asOdooString(r['tanggal_ajukan']),
      alasanTolak: asOdooString(r['alasan_tolak']),
    );
  }).toList();
});

final usulanDetailProvider = FutureProvider.autoDispose
    .family<UsulanDetail, int>((ref, usulanId) async {
      final api = ref.read(apiClientProvider);
      final rows =
          await api.callKw(
                model: 'tarombo.usulan',
                method: 'search_read',
                args: [
                  [
                    ['id', '=', usulanId],
                    [
                      'active',
                      'in',
                      [true, false],
                    ],
                  ],
                ],
                kwargs: {
                  'fields': [
                    'name',
                    'jenis',
                    'state',
                    'punguan_id',
                    'orang_id',
                    'ayah_id',
                    'usul_nama',
                    'usul_jenis_kelamin',
                    'usul_masih_hidup',
                    'usul_urutan',
                    'usul_tanggal_lahir',
                    'usul_tanggal_wafat',
                    'usul_provinsi_id',
                    'usul_kabupaten_id',
                    'usul_kecamatan_id',
                    'usul_desa_id',
                    'usul_alamat_jalan',
                    'usul_no_telp',
                    'usul_email_kontak',
                    'usul_latitude',
                    'usul_longitude',
                    'usul_suami_nama',
                    'usul_suami_marga_id',
                    'usul_foto',
                    'catatan',
                    'sumber_ket',
                    'tanggal_ajukan',
                    'peninjau_id',
                    'tanggal_tinjau',
                    'alasan_tolak',
                    'lampiran_ids',
                  ],
                  'limit': 1,
                },
              )
              as List;
      if (rows.isEmpty) {
        throw Exception('Usulan tidak ditemukan.');
      }
      final r = (rows.first as Map).cast<String, dynamic>();

      final jenis = r['jenis'] as String;
      final target = jenis == 'tambah' ? r['ayah_id'] : r['orang_id'];
      final wilayahBagian = [
        _m2oName(r['usul_desa_id']),
        _m2oName(r['usul_kecamatan_id']),
        _m2oName(r['usul_kabupaten_id']),
        _m2oName(r['usul_provinsi_id']),
      ].whereType<String>().toList();

      final lampiranIds = (r['lampiran_ids'] as List?)?.cast<int>() ?? const [];
      List<LampiranItem> lampiran = const [];
      if (lampiranIds.isNotEmpty) {
        final attRows =
            await api.callKw(
                  model: 'ir.attachment',
                  method: 'read',
                  args: [
                    lampiranIds,
                    ['name'],
                  ],
                )
                as List;
        lampiran = attRows
            .cast<Map<String, dynamic>>()
            .map(
              (a) => LampiranItem(
                id: a['id'] as int,
                name: asOdooString(a['name']) ?? 'Berkas',
              ),
            )
            .toList();
      }

      return UsulanDetail(
        id: r['id'] as int,
        name: r['name'] as String,
        jenis: jenis,
        state: r['state'] as String,
        punguan: _m2oName(r['punguan_id']),
        targetName: (target is List && target.length > 1)
            ? target[1] as String
            : null,
        usulNama: asOdooString(r['usul_nama']),
        usulJenisKelamin: asOdooString(r['usul_jenis_kelamin']),
        usulMasihHidup: asOdooString(r['usul_masih_hidup']),
        usulUrutan: r['usul_urutan'] == false ? null : r['usul_urutan'] as int?,
        usulTanggalLahir: asOdooDate(r['usul_tanggal_lahir']),
        usulTanggalWafat: asOdooDate(r['usul_tanggal_wafat']),
        usulWilayah: wilayahBagian.isEmpty ? null : wilayahBagian.join(' - '),
        usulAlamatJalan: asOdooString(r['usul_alamat_jalan']),
        usulNoTelp: asOdooString(r['usul_no_telp']),
        usulEmailKontak: asOdooString(r['usul_email_kontak']),
        usulLatitude:
            (r['usul_latitude'] is num && (r['usul_latitude'] as num) != 0)
            ? (r['usul_latitude'] as num).toDouble()
            : null,
        usulLongitude:
            (r['usul_longitude'] is num && (r['usul_longitude'] as num) != 0)
            ? (r['usul_longitude'] as num).toDouble()
            : null,
        usulSuamiNama: asOdooString(r['usul_suami_nama']),
        usulSuamiMarga: _m2oName(r['usul_suami_marga_id']),
        adaFoto: r['usul_foto'] != false && r['usul_foto'] != null,
        catatan: asOdooString(r['catatan']),
        sumberKet: asOdooString(r['sumber_ket']) ?? '-',
        tanggalAjukan: asOdooDateTime(r['tanggal_ajukan']),
        peninjau: _m2oName(r['peninjau_id']),
        tanggalTinjau: asOdooDateTime(r['tanggal_tinjau']),
        alasanTolak: asOdooString(r['alasan_tolak']),
        lampiran: lampiran,
      );
    });

String? _m2oName(dynamic v) =>
    (v is List && v.length > 1) ? v[1] as String : null;

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
    String? usulAlamatJalan,
    String? usulNoTelp,
    String? usulEmailKontak,
    double? usulLatitude,
    double? usulLongitude,
    String? usulTanggalLahir,
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
          if (usulAlamatJalan != null && usulAlamatJalan.isNotEmpty)
            'usul_alamat_jalan': usulAlamatJalan,
          if (usulNoTelp != null && usulNoTelp.isNotEmpty)
            'usul_no_telp': usulNoTelp,
          if (usulEmailKontak != null && usulEmailKontak.isNotEmpty)
            'usul_email_kontak': usulEmailKontak,
          'usul_latitude': ?usulLatitude,
          'usul_longitude': ?usulLongitude,
          'usul_tanggal_lahir': ?usulTanggalLahir,
        },
      ],
    );
    await api.callKw(
      model: 'tarombo.usulan',
      method: 'action_ajukan',
      args: [
        [id],
      ],
    );
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
    String? usulAlamatJalan,
    String? usulNoTelp,
    String? usulEmailKontak,
    double? usulLatitude,
    double? usulLongitude,
    String? usulTanggalLahir,
    String? usulTanggalWafat,
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
          if (usulSuamiNama != null && usulSuamiNama.isNotEmpty)
            'usul_suami_nama': usulSuamiNama,
          'usul_suami_marga_id': ?usulSuamiMargaId,
          if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
          'usul_foto': ?fotoBase64,
          if (usulAlamatJalan != null && usulAlamatJalan.isNotEmpty)
            'usul_alamat_jalan': usulAlamatJalan,
          if (usulNoTelp != null && usulNoTelp.isNotEmpty)
            'usul_no_telp': usulNoTelp,
          if (usulEmailKontak != null && usulEmailKontak.isNotEmpty)
            'usul_email_kontak': usulEmailKontak,
          'usul_latitude': ?usulLatitude,
          'usul_longitude': ?usulLongitude,
          'usul_tanggal_lahir': ?usulTanggalLahir,
          'usul_tanggal_wafat': ?usulTanggalWafat,
        },
      ],
    );
    await api.callKw(
      model: 'tarombo.usulan',
      method: 'action_ajukan',
      args: [
        [id],
      ],
    );
    ref.invalidate(usulanListProvider);
  }
}
