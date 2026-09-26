/// Label tampilan untuk field tarombo.orang. Nilai mentah di database TIDAK
/// diubah (tetap 'sahih'/'rumpang') — cuma label yang ditampilkan ke pengguna.
String statusLabel(String? status) {
  switch (status) {
    case 'sahih':
      return 'Terverifikasi';
    case 'rumpang':
      return 'Belum Terverifikasi';
    default:
      return '-';
  }
}

String jenisKelaminLabel(String? jk) => jk == 'P' ? 'Perempuan' : 'Laki-laki';

const Map<String, String> bidangLabels = {
  'tani': 'Pertanian',
  'dagang': 'Perdagangan',
  'asn': 'ASN',
  'swasta': 'Swasta',
  'wiraswasta': 'Wiraswasta',
  'pendidik': 'Pendidik',
  'kesehatan': 'Kesehatan',
  'rohani': 'Rohaniwan',
  'lain': 'Lain-lain',
};

const Map<String, String> jenjangLabels = {
  'sd': 'SD',
  'smp': 'SMP',
  'sma': 'SMA',
  'd1': 'D1',
  'd3': 'D3',
  'd4': 'D4',
  's1': 'S1',
  's2': 'S2',
  's3': 'S3',
  'lain': 'Lain-lain',
};

String bidangLabel(String? v) => v == null ? '-' : (bidangLabels[v] ?? v);
String jenjangLabel(String? v) => v == null ? '-' : (jenjangLabels[v] ?? v);
