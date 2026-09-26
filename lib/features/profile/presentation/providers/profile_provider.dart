import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/utils/odoo_json.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/orang_ringkas.dart';

final profileDetailProvider = FutureProvider.autoDispose.family<ProfileDetail, int>((ref, orangId) async {
  final api = ref.read(apiClientProvider);

  final rows = await api.callKw(
    model: 'tarombo.orang',
    method: 'search_read',
    args: [
      [
        ['id', '=', orangId]
      ]
    ],
    kwargs: {
      'fields': ['name', 'jenis_kelamin', 'sundut', 'status', 'punguan_id', 'ayah_id', 'parent_path'],
      'limit': 1,
    },
  ) as List;
  if (rows.isEmpty) {
    throw Exception('Data orang tidak ditemukan.');
  }
  final row = rows.first as Map<String, dynamic>;

  // ── Leluhur: dibaca langsung dari parent_path ("1/5/12/"), field bawaan
  // Odoo untuk _parent_store — tidak perlu panggilan tambahan ke pohon.
  final pathIds = (asOdooString(row['parent_path']) ?? '')
      .split('/')
      .where((s) => s.isNotEmpty)
      .map(int.parse)
      .toList();
  final ancestorIds = pathIds.length > 1 ? pathIds.sublist(0, pathIds.length - 1).reversed.toList() : <int>[];

  List<OrangRingkas> leluhur = [];
  if (ancestorIds.isNotEmpty) {
    final ancestorRows = await api.callKw(
      model: 'tarombo.orang',
      method: 'search_read',
      args: [
        [
          ['id', 'in', ancestorIds]
        ]
      ],
      kwargs: {
        'fields': ['id', 'name', 'sundut', 'jenis_kelamin', 'punguan_id'],
      },
    ) as List;
    final byId = {for (final r in ancestorRows.cast<Map<String, dynamic>>()) r['id'] as int: r};
    leluhur = [
      for (var i = 0; i < ancestorIds.length; i++)
        if (byId[ancestorIds[i]] != null) _toRingkas(byId[ancestorIds[i]]!, level: i + 1)
    ];
  }

  // ── Keturunan: reuse get_pohon_data (mode 'cabang') yang sudah dibatasi
  // server (maks 4 generasi / 200 simpul untuk komponen pohon web) lalu
  // diratakan jadi list di sini — MVP mobile sengaja tanpa visual pohon.
  final pohon = await api.callKw(model: 'tarombo.orang', method: 'get_pohon_data', args: [orangId, 'cabang']) as Map;
  final fokusNode = _cariFokus(pohon.cast<String, dynamic>());
  final keturunan = <OrangRingkas>[];
  var terpotong = false;
  if (fokusNode != null) {
    _ratakanKeturunan(fokusNode, 1, keturunan, () => terpotong = true);
  }

  return ProfileDetail(
    id: row['id'] as int,
    name: row['name'] as String,
    jenisKelamin: row['jenis_kelamin'] as String,
    sundut: row['sundut'] as int,
    status: asOdooString(row['status']) ?? 'rumpang',
    punguan: _m2oName(row['punguan_id']),
    ayahId: _m2oId(row['ayah_id']),
    ayahName: _m2oName(row['ayah_id']),
    leluhur: leluhur,
    keturunan: keturunan,
    keturunanMungkinTerpotong: terpotong,
  );
});

OrangRingkas _toRingkas(Map<String, dynamic> r, {int level = 0}) => OrangRingkas(
      id: r['id'] as int,
      name: r['name'] as String,
      sundut: r['sundut'] as int,
      jenisKelamin: r['jenis_kelamin'] as String,
      punguan: _m2oName(r['punguan_id']),
      level: level,
    );

String? _m2oName(dynamic v) => (v is List && v.length > 1) ? v[1] as String : null;
int? _m2oId(dynamic v) => (v is List && v.isNotEmpty) ? v[0] as int : null;

Map<String, dynamic>? _cariFokus(Map<String, dynamic> node) {
  if (node['selected'] == true) return node;
  for (final child in (node['children'] as List? ?? const [])) {
    final found = _cariFokus(child as Map<String, dynamic>);
    if (found != null) return found;
  }
  return null;
}

void _ratakanKeturunan(Map<String, dynamic> node, int level, List<OrangRingkas> out, void Function() onTerpotong) {
  for (final childRaw in (node['children'] as List? ?? const [])) {
    final child = childRaw as Map<String, dynamic>;
    out.add(OrangRingkas(
      id: child['id'] as int,
      name: child['name'] as String,
      sundut: child['sundut'] as int,
      jenisKelamin: child['jenis_kelamin'] as String,
      level: level,
    ));
    if (child['has_more'] == true) onTerpotong();
    _ratakanKeturunan(child, level + 1, out, onTerpotong);
  }
}
