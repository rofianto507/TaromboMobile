import '../../../../shared/utils/odoo_json.dart';

class ArsipItem {
  final int id;
  final String name;
  final String jenis;
  final String? orangName;
  final String? punguan;
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
    this.orangName,
    this.punguan,
    this.tahunPerkiraan,
    this.sumber,
    this.keterangan,
    this.berkasNama,
    this.createUid,
  });

  factory ArsipItem.fromJson(Map<String, dynamic> json) {
    String? m2oName(dynamic v) => (v is List && v.length > 1) ? v[1] as String : null;
    return ArsipItem(
      id: json['id'] as int,
      name: json['name'] as String,
      jenis: asOdooString(json['jenis']) ?? 'dokumen',
      orangName: m2oName(json['orang_id']),
      punguan: m2oName(json['punguan_id']),
      tahunPerkiraan: asOdooString(json['tahun_perkiraan']),
      sumber: asOdooString(json['sumber']),
      keterangan: asOdooString(json['keterangan']),
      berkasNama: asOdooString(json['berkas_nama']),
      createUid: (json['create_uid'] is List && (json['create_uid'] as List).isNotEmpty)
          ? (json['create_uid'] as List).first as int
          : null,
    );
  }
}
