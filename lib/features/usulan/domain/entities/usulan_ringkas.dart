enum UsulanState { draft, diajukan, disetujui, ditolak }

UsulanState usulanStateFromServer(String s) {
  switch (s) {
    case 'diajukan':
      return UsulanState.diajukan;
    case 'disetujui':
      return UsulanState.disetujui;
    case 'ditolak':
      return UsulanState.ditolak;
    default:
      return UsulanState.draft;
  }
}

String usulanStateLabel(UsulanState s) {
  switch (s) {
    case UsulanState.draft:
      return 'Draft';
    case UsulanState.diajukan:
      return 'Diajukan';
    case UsulanState.disetujui:
      return 'Disetujui';
    case UsulanState.ditolak:
      return 'Ditolak';
  }
}

String jenisUsulanLabel(String jenis) {
  switch (jenis) {
    case 'tambah':
      return 'Tambah Orang Baru';
    case 'koreksi':
      return 'Koreksi Data';
    case 'lengkapi':
      return 'Lengkapi Data';
    case 'istri':
      return 'Data Istri';
    default:
      return jenis;
  }
}

class UsulanRingkas {
  final int id;
  final String name;
  final String jenis;
  final UsulanState state;
  final String? targetName; // orang_id atau ayah_id, mana yang terisi
  final String? tanggalAjukan;
  final String? alasanTolak;

  const UsulanRingkas({
    required this.id,
    required this.name,
    required this.jenis,
    required this.state,
    this.targetName,
    this.tanggalAjukan,
    this.alasanTolak,
  });
}
