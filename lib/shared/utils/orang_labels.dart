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

// Bidang pekerjaan TIDAK lagi punya daftar tetap di sini — sejak
// tarombo.bidang jadi model tersendiri yang dikelola bebas oleh
// pengurus/admin, namanya sudah datang langsung dari server (lihat
// direktori_keahlian_screen.dart), jadi tidak perlu tabel terjemahan lokal.

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

String jenjangLabel(String? v) => v == null ? '-' : (jenjangLabels[v] ?? v);
