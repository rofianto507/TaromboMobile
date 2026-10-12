import '../../../../shared/utils/odoo_json.dart';

/// Rujukan ringkas ke satu tarombo.wilayah (hasil Many2one `[id, nama]`).
class WilayahRef {
  final int id;
  final String name;
  const WilayahRef(this.id, this.name);

  static WilayahRef? fromM2o(dynamic v) => (v is List && v.length > 1)
      ? WilayahRef(v[0] as int, v[1] as String)
      : null;
}

class ButirKelengkapan {
  final String key;
  final String label;
  final bool selesai;
  const ButirKelengkapan({
    required this.key,
    required this.label,
    required this.selesai,
  });
}

class KelengkapanProfil {
  final int persen;
  final List<ButirKelengkapan> butir;
  const KelengkapanProfil({required this.persen, required this.butir});

  bool get lengkap => persen >= 100;

  /// Butir pertama yang belum diisi — dipakai sebagai ajakan di beranda.
  ButirKelengkapan? get berikutnya {
    for (final b in butir) {
      if (!b.selesai) return b;
    }
    return null;
  }

  factory KelengkapanProfil.fromJson(Map<String, dynamic> json) =>
      KelengkapanProfil(
        persen: (json['persen'] as num?)?.toInt() ?? 0,
        butir: [
          for (final b in (json['butir'] as List? ?? const []))
            ButirKelengkapan(
              key: (b as Map)['key'] as String,
              label: b['label'] as String,
              selesai: b['selesai'] == true,
            ),
        ],
      );
}

/// Data profil milik akun yang login (get_profil_saya di backend), termasuk
/// field yang tidak terlihat anggota lain seperti tanggal lahir persis.
class ProfilSaya {
  final int id;
  final String name;
  final String jenisKelamin;
  final bool punyaFoto;
  final DateTime? tanggalLahir;
  final WilayahRef? provinsi;
  final WilayahRef? kabupaten;
  final WilayahRef? kecamatan;
  final WilayahRef? desa;
  final String? alamatJalan;
  final String? alamatCatatan;
  // Kontak pribadi — hanya terlihat oleh pemilik dan pengurus.
  final String? noTelp;
  final String? emailKontak;
  // Titik rumah di peta (null bila belum diisi). Tampil ke anggota lain HANYA
  // bila berbagiLokasi aktif.
  final double? latitude;
  final double? longitude;
  final bool berbagiLokasi;
  final KelengkapanProfil kelengkapan;

  const ProfilSaya({
    required this.id,
    required this.name,
    required this.jenisKelamin,
    required this.punyaFoto,
    required this.kelengkapan,
    this.tanggalLahir,
    this.provinsi,
    this.kabupaten,
    this.kecamatan,
    this.desa,
    this.alamatJalan,
    this.alamatCatatan,
    this.noTelp,
    this.emailKontak,
    this.latitude,
    this.longitude,
    this.berbagiLokasi = false,
  });

  factory ProfilSaya.fromJson(Map<String, dynamic> json) => ProfilSaya(
    id: json['id'] as int,
    name: json['name'] as String,
    jenisKelamin: asOdooString(json['jenis_kelamin']) ?? 'L',
    punyaFoto: json['punya_foto'] == true,
    tanggalLahir: asOdooDate(json['tanggal_lahir']),
    provinsi: WilayahRef.fromM2o(json['provinsi_id']),
    kabupaten: WilayahRef.fromM2o(json['kabupaten_id']),
    kecamatan: WilayahRef.fromM2o(json['kecamatan_id']),
    desa: WilayahRef.fromM2o(json['desa_id']),
    alamatJalan: asOdooString(json['alamat_jalan']),
    alamatCatatan: asOdooString(json['alamat_catatan']),
    noTelp: asOdooString(json['no_telp']),
    emailKontak: asOdooString(json['email_kontak']),
    latitude: json['latitude'] is num
        ? (json['latitude'] as num).toDouble()
        : null,
    longitude: json['longitude'] is num
        ? (json['longitude'] as num).toDouble()
        : null,
    berbagiLokasi: json['berbagi_lokasi'] == true,
    kelengkapan: KelengkapanProfil.fromJson(
      (json['kelengkapan'] as Map).cast<String, dynamic>(),
    ),
  );
}
