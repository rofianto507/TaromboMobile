class KerabatLokasi {
  final int id;
  final String name;
  final double lat;
  final double lng;
  final int sundut;
  final String jenisKelamin;
  final String? punguan;
  final bool punyaFoto;
  double? jarakKm; // dihitung di client setelah posisi device diketahui

  KerabatLokasi({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.sundut,
    required this.jenisKelamin,
    this.punguan,
    required this.punyaFoto,
    this.jarakKm,
  });

  factory KerabatLokasi.fromJson(Map<String, dynamic> json) => KerabatLokasi(
        id: json['id'] as int,
        name: json['name'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        sundut: json['sundut'] as int,
        jenisKelamin: json['jenis_kelamin'] as String,
        punguan: json['punguan'] as String?,
        punyaFoto: json['punya_foto'] as bool,
      );
}
