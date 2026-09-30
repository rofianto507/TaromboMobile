import '../../../../shared/utils/odoo_json.dart';

/// Cermin persis struktur dict yang dikembalikan `tarombo.orang.get_pohon_data()`
/// di backend (lihat models/tarombo_pohon.py) — sengaja TIDAK dibangun ulang
/// di sisi Flutter, backend sudah membatasi kedalaman & jumlah simpul.
class PohonNode {
  final int id;
  final String name;
  final int sundut;
  final String jenisKelamin;
  final String status;
  final bool punyaFoto;
  final bool selected;
  final bool collapsed;
  final bool hasMore;
  // True HANYA untuk node akar (ayah) hasil mode 'cabang', ketika ayah itu
  // sendiri masih punya ayah_id yang tidak ikut ditampilkan. Tanpa flag ini,
  // pohon terlihat "berhenti/tidak ada data lagi" di titik paling atas,
  // padahal datanya masih ada — cuma belum dimuat (lihat _pohon_cabang di
  // backend). Lihat juga [tertutup].
  final bool hasMoreAtas;
  final List<PohonNode> children;

  const PohonNode({
    required this.id,
    required this.name,
    required this.sundut,
    required this.jenisKelamin,
    required this.status,
    required this.punyaFoto,
    required this.selected,
    required this.collapsed,
    required this.hasMore,
    required this.hasMoreAtas,
    required this.children,
  });

  /// Node ini "tertutup" — ada data lain (keturunan DI BAWAH atau leluhur DI
  /// ATAS) yang sengaja tidak dikirim backend (batas kedalaman/jumlah
  /// simpul, saudara yang sengaja ditutup, atau ayah dari node akar). Tap di
  /// sini artinya "buka pohon berpusat pada orang ini", bukan membuka profil
  /// langsung.
  bool get tertutup => collapsed || hasMore || hasMoreAtas;

  factory PohonNode.fromJson(Map<String, dynamic> json) => PohonNode(
        id: json['id'] as int,
        name: json['name'] as String,
        sundut: json['sundut'] as int? ?? 0,
        jenisKelamin: asOdooString(json['jenis_kelamin']) ?? '',
        status: asOdooString(json['status']) ?? '',
        punyaFoto: json['punya_foto'] == true,
        selected: json['selected'] == true,
        collapsed: json['collapsed'] == true,
        hasMore: json['has_more'] == true,
        hasMoreAtas: json['has_more_atas'] == true,
        children: (json['children'] as List? ?? const [])
            .map((e) => PohonNode.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}
