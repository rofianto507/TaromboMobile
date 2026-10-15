import '../../../../shared/utils/odoo_json.dart';

/// Satu anggota yang terkait dengan arsip. Nama diisi belakangan lewat
/// ArsipRepository.isiNamaOrang karena search_read hanya mengembalikan id.
class ArsipOrang {
  final int id;
  final String name;
  const ArsipOrang({required this.id, this.name = ''});
}

class ArsipItem {
  final int id;
  final String name;
  final String jenis;
  final List<ArsipOrang> orang;
  final String? tahunPerkiraan;
  final String? sumber;
  final String? keterangan;
  final String? berkasNama;
  // Akun pengunggah — dipakai app untuk menentukan boleh-tidaknya menghapus.
  final int? createUid;

  const ArsipItem({
    required this.id,
    required this.name,
    required this.jenis,
    this.orang = const [],
    this.tahunPerkiraan,
    this.sumber,
    this.keterangan,
    this.berkasNama,
    this.createUid,
  });

  factory ArsipItem.fromJson(Map<String, dynamic> json) {
    return ArsipItem(
      id: json['id'] as int,
      name: json['name'] as String,
      jenis: asOdooString(json['jenis']) ?? 'dokumen',
      orang: [
        for (final v
            in (json['orang_ids'] is List
                ? json['orang_ids'] as List
                : const []))
          if (v is int) ArsipOrang(id: v),
      ],
      tahunPerkiraan: asOdooString(json['tahun_perkiraan']),
      sumber: asOdooString(json['sumber']),
      keterangan: asOdooString(json['keterangan']),
      berkasNama: asOdooString(json['berkas_nama']),
      createUid:
          (json['create_uid'] is List &&
              (json['create_uid'] as List).isNotEmpty)
          ? (json['create_uid'] as List).first as int
          : null,
    );
  }

  /// Salinan dengan nama orang terisi dari [nama] (id -> nama).
  ArsipItem denganNamaOrang(Map<int, String> nama) => ArsipItem(
    id: id,
    name: name,
    jenis: jenis,
    orang: [
      for (final o in orang) ArsipOrang(id: o.id, name: nama[o.id] ?? o.name),
    ],
    tahunPerkiraan: tahunPerkiraan,
    sumber: sumber,
    keterangan: keterangan,
    berkasNama: berkasNama,
    createUid: createUid,
  );

  /// "Budi" / "Budi, Ani" / "Budi +2" — ringkas untuk kartu daftar.
  String? get ringkasOrang {
    final nama = [
      for (final o in orang)
        if (o.name.isNotEmpty) o.name,
    ];
    if (nama.isEmpty) return null;
    if (nama.length == 1) return nama.first;
    if (nama.length == 2) return nama.join(', ');
    return '${nama.first} +${nama.length - 1}';
  }
}
