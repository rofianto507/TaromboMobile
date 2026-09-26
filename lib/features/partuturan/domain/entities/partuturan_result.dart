class NamaId {
  final int id;
  final String name;
  const NamaId({required this.id, required this.name});
}

class PartuturanResult {
  final int? ancId;
  final String? ancName;
  final List<NamaId> jalurA;
  final List<NamaId> jalurB;
  final String sebutanA;
  final String sebutanB;
  final bool seniorA;
  final int jarak;
  final String keterangan;

  const PartuturanResult({
    required this.ancId,
    required this.ancName,
    required this.jalurA,
    required this.jalurB,
    required this.sebutanA,
    required this.sebutanB,
    required this.seniorA,
    required this.jarak,
    required this.keterangan,
  });

  factory PartuturanResult.fromJson(Map<String, dynamic> json) => PartuturanResult(
        ancId: json['anc_id'] == false ? null : json['anc_id'] as int?,
        ancName: json['anc_name'] == false ? null : json['anc_name'] as String?,
        jalurA: (json['jalur_a'] as List).map((e) => NamaId(id: e['id'] as int, name: e['name'] as String)).toList(),
        jalurB: (json['jalur_b'] as List).map((e) => NamaId(id: e['id'] as int, name: e['name'] as String)).toList(),
        sebutanA: json['sebutan_a'] as String,
        sebutanB: json['sebutan_b'] as String,
        seniorA: json['senior_a'] as bool,
        jarak: json['jarak'] as int,
        keterangan: json['keterangan'] as String,
      );
}
