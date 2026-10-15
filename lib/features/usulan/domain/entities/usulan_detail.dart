class LampiranItem {
  final int id;
  final String name;
  const LampiranItem({required this.id, required this.name});
}

class UsulanDetail {
  final int id;
  final String name;
  final String jenis;
  final String state;
  final String? punguan;
  final String? targetName; // orang_id (koreksi) atau ayah_id (tambah)

  final String? usulNama;
  final String? usulJenisKelamin;
  final String? usulMasihHidup; // 'ya'/'tidak'/null
  final int? usulUrutan;
  final DateTime? usulTanggalLahir;
  final DateTime? usulTanggalWafat;
  final int? usulTahunLahir;
  final int? usulTahunWafat;
  final String?
  usulWilayah; // gabungan provinsi/kabupaten/kecamatan/desa yang terisi
  final String? usulAlamatJalan;
  final String? usulNoTelp;
  final String? usulEmailKontak;
  final double? usulLatitude;
  final double? usulLongitude;
  final String? usulSuamiNama;
  final String? usulSuamiMarga;
  final bool adaFoto;

  final String? catatan;
  final String sumberKet;
  final DateTime? tanggalAjukan;
  final String? peninjau;
  final DateTime? tanggalTinjau;
  final String? alasanTolak;
  final List<LampiranItem> lampiran;

  const UsulanDetail({
    required this.id,
    required this.name,
    required this.jenis,
    required this.state,
    this.punguan,
    this.targetName,
    this.usulNama,
    this.usulJenisKelamin,
    this.usulMasihHidup,
    this.usulUrutan,
    this.usulTanggalLahir,
    this.usulTanggalWafat,
    this.usulTahunLahir,
    this.usulTahunWafat,
    this.usulWilayah,
    this.usulAlamatJalan,
    this.usulNoTelp,
    this.usulEmailKontak,
    this.usulLatitude,
    this.usulLongitude,
    this.usulSuamiNama,
    this.usulSuamiMarga,
    this.adaFoto = false,
    this.catatan,
    required this.sumberKet,
    this.tanggalAjukan,
    this.peninjau,
    this.tanggalTinjau,
    this.alasanTolak,
    this.lampiran = const [],
  });
}
