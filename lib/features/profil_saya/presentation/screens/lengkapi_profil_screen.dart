import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../../shared/utils/orang_labels.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/orang_avatar.dart';
import '../../../../shared/widgets/lokasi_picker_screen.dart';
import '../../../../shared/widgets/wilayah_picker_sheet.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/presentation/widgets/riwayat_form_sheet.dart';
import '../../domain/entities/profil_saya.dart';
import '../providers/profil_saya_provider.dart';
import '../widgets/kelengkapan_profil_card.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold = Color(0xFFC8A24A);

/// Pemilik akun melengkapi data dirinya sendiri (foto, tanggal lahir,
/// domisili) — tersimpan langsung, tanpa usulan. Nama dan hubungan keluarga
/// tetap lewat Usulan karena mengubah data bersama.
class LengkapiProfilScreen extends ConsumerStatefulWidget {
  const LengkapiProfilScreen({super.key});

  @override
  ConsumerState<LengkapiProfilScreen> createState() =>
      _LengkapiProfilScreenState();
}

class _LengkapiProfilScreenState extends ConsumerState<LengkapiProfilScreen> {
  final _alamat = TextEditingController();
  final _telp = TextEditingController();
  final _email = TextEditingController();
  bool _terisi = false;
  bool _saving = false;

  Uint8List? _fotoBaru;
  DateTime? _tanggalLahir;
  WilayahRef? _provinsi;
  WilayahRef? _kabupaten;
  WilayahRef? _kecamatan;
  WilayahRef? _desa;
  LatLng? _titik;

  @override
  void dispose() {
    _alamat.dispose();
    _telp.dispose();
    _email.dispose();
    super.dispose();
  }

  // Salin nilai server ke form SEKALI saja — pemuatan ulang provider setelah
  // simpan tidak boleh menimpa ketikan yang sedang berjalan.
  void _isiDari(ProfilSaya p) {
    if (_terisi) return;
    _terisi = true;
    _tanggalLahir = p.tanggalLahir;
    _provinsi = p.provinsi;
    _kabupaten = p.kabupaten;
    _kecamatan = p.kecamatan;
    _desa = p.desa;
    _alamat.text = p.alamatJalan ?? '';
    _telp.text = p.noTelp ?? '';
    _email.text = p.emailKontak ?? '';
    _titik = (p.latitude != null && p.longitude != null)
        ? LatLng(p.latitude!, p.longitude!)
        : null;
  }

  Future<void> _pilihFoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _fotoBaru = bytes);
  }

  Future<void> _pilihTanggal() async {
    final sekarang = DateTime.now();
    final hasil = await showDatePicker(
      context: context,
      initialDate: _tanggalLahir ?? DateTime(sekarang.year - 30),
      firstDate: DateTime(1900),
      lastDate: sekarang,
      helpText: 'Tanggal lahir',
    );
    if (hasil != null) setState(() => _tanggalLahir = hasil);
  }

  Future<void> _pilihWilayah(String tingkat) async {
    final (judul, indukId) = switch (tingkat) {
      '1' => ('Pilih Provinsi', null),
      '2' => ('Pilih Kabupaten/Kota', _provinsi?.id),
      '3' => ('Pilih Kecamatan', _kabupaten?.id),
      _ => ('Pilih Desa/Kelurahan', _kecamatan?.id),
    };
    final w = await showWilayahPicker(
      context,
      tingkat: tingkat,
      judul: judul,
      indukId: indukId,
    );
    if (w == null) return;
    setState(() {
      // Mengganti satu tingkat mengosongkan tingkat di bawahnya.
      switch (tingkat) {
        case '1':
          if (_provinsi?.id != w.id) _kabupaten = _kecamatan = _desa = null;
          _provinsi = w;
        case '2':
          if (_kabupaten?.id != w.id) _kecamatan = _desa = null;
          _kabupaten = w;
        case '3':
          if (_kecamatan?.id != w.id) _desa = null;
          _kecamatan = w;
        default:
          _desa = w;
      }
    });
  }

  void _hapusWilayah(String tingkat) {
    setState(() {
      switch (tingkat) {
        case '1':
          _provinsi = _kabupaten = _kecamatan = _desa = null;
        case '2':
          _kabupaten = _kecamatan = _desa = null;
        case '3':
          _kecamatan = _desa = null;
        default:
          _desa = null;
      }
    });
  }

  Future<void> _pilihTitik() async {
    final hasil = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => LokasiPickerScreen(titikAwal: _titik)),
    );
    if (hasil != null) setState(() => _titik = hasil);
  }

  Future<void> _simpan(ProfilSaya awal) async {
    final vals = <String, dynamic>{};
    if (_fotoBaru != null) vals['foto'] = base64Encode(_fotoBaru!);
    if (_tanggalLahir != awal.tanggalLahir) {
      vals['tanggal_lahir'] = _tanggalLahir == null
          ? false
          : DateFormat('yyyy-MM-dd').format(_tanggalLahir!);
    }
    final wilayahBerubah =
        _provinsi?.id != awal.provinsi?.id ||
        _kabupaten?.id != awal.kabupaten?.id ||
        _kecamatan?.id != awal.kecamatan?.id ||
        _desa?.id != awal.desa?.id;
    if (wilayahBerubah) {
      // Kirim keempatnya sekaligus supaya server tidak mengisi ulang induk
      // dari nilai lama saat sebuah tingkat sengaja dikosongkan.
      vals['provinsi_id'] = _provinsi?.id ?? false;
      vals['kabupaten_id'] = _kabupaten?.id ?? false;
      vals['kecamatan_id'] = _kecamatan?.id ?? false;
      vals['desa_id'] = _desa?.id ?? false;
    }
    final alamat = _alamat.text.trim();
    if (alamat != (awal.alamatJalan ?? '')) vals['alamat_jalan'] = alamat;
    final telp = _telp.text.trim();
    if (telp != (awal.noTelp ?? '')) vals['no_telp'] = telp;
    final email = _email.text.trim();
    if (email != (awal.emailKontak ?? '')) vals['email_kontak'] = email;

    // Titik rumah: dikirim berpasangan; menghapusnya mengirim keduanya false.
    final titikAwal = (awal.latitude != null && awal.longitude != null)
        ? LatLng(awal.latitude!, awal.longitude!)
        : null;
    if (_titik?.latitude != titikAwal?.latitude ||
        _titik?.longitude != titikAwal?.longitude) {
      vals['latitude'] = _titik?.latitude ?? false;
      vals['longitude'] = _titik?.longitude ?? false;
    }

    if (vals.isEmpty) {
      context.pop();
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(profilSayaRepositoryProvider).simpan(awal.id, vals);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil tersimpan.')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(profilSayaProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Lengkapi Profil')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Gagal memuat profil.\n$e', textAlign: TextAlign.center),
        ),
        data: (p) {
          if (p == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Akun Anda belum tertaut ke data anggota. Selesaikan klaim identitas dulu.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          _isiDari(p);
          return _form(p);
        },
      ),
    );
  }

  Future<void> _hapusRiwayat(String nama, Future<void> Function() aksi) async {
    final yakin = await showAppConfirmDialog(
      context,
      title: 'Hapus riwayat?',
      message: '"$nama" akan dihapus dari profil Anda.',
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!yakin) return;
    try {
      await aksi();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }

  /// Pendidikan & pekerjaan dikelola langsung di sini (tanpa pindah layar):
  /// tambah dan hapus tersimpan seketika, terpisah dari tombol Simpan di bawah.
  List<Widget> _riwayat(ProfilSaya p) {
    final detail = ref.watch(profileDetailProvider(p.id)).valueOrNull;
    final repo = ref.read(riwayatRepositoryProvider);
    Widget kosong(String teks) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(teks, style: const TextStyle(color: Colors.grey)),
    );
    return [
      _JudulAksi(
        teks: 'Riwayat pendidikan',
        onTambah: () => showPendidikanFormSheet(context, p.id),
      ),
      if (detail == null)
        const _Memuat()
      else if (detail.pendidikan.isEmpty)
        kosong('Belum ada data pendidikan.')
      else
        for (final d in detail.pendidikan)
          _BarisRiwayat(
            ikon: Icons.school_outlined,
            judul: d.institusi,
            keterangan: [
              if (d.jenjang != null) jenjangLabel(d.jenjang),
              if (d.jurusan != null) d.jurusan!,
              if (d.tahunMasuk != null || d.tahunLulus != null)
                '${d.tahunMasuk ?? '?'}–${d.lulus ? (d.tahunLulus ?? '?') : 'sekarang'}',
            ].join(' • '),
            onHapus: () => _hapusRiwayat(
              d.institusi,
              () => repo.hapusPendidikan(p.id, d.id),
            ),
          ),
      const SizedBox(height: 16),
      _JudulAksi(
        teks: 'Riwayat pekerjaan',
        onTambah: () => showPekerjaanFormSheet(context, p.id),
      ),
      if (detail == null)
        const _Memuat()
      else if (detail.pekerjaan.isEmpty)
        kosong('Belum ada data pekerjaan.')
      else
        for (final k in detail.pekerjaan)
          _BarisRiwayat(
            ikon: Icons.work_outline_rounded,
            judul: k.jabatan,
            keterangan: [
              if (k.instansi != null) k.instansi!,
              if (k.bidang != null) k.bidang!,
              if (k.tahunMulai != null)
                '${k.tahunMulai}–${k.sekarang ? 'sekarang' : (k.tahunSelesai ?? '?')}',
            ].join(' • '),
            onHapus: () =>
                _hapusRiwayat(k.jabatan, () => repo.hapusPekerjaan(p.id, k.id)),
          ),
      const _Catatan('Tambah dan hapus riwayat tersimpan langsung.'),
      const SizedBox(height: 24),
    ];
  }

  Widget _form(ProfilSaya p) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        KelengkapanProfilCard(kelengkapan: p.kelengkapan, rinci: true),
        const SizedBox(height: 20),

        const _Judul('Foto profil'),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _kGold, width: 2),
              ),
              child: _fotoBaru != null
                  ? CircleAvatar(
                      radius: 36,
                      backgroundImage: MemoryImage(_fotoBaru!),
                    )
                  : OrangAvatar(
                      orangId: p.id,
                      jenisKelamin: p.jenisKelamin,
                      radius: 36,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saving ? null : _pilihFoto,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  p.punyaFoto || _fotoBaru != null
                      ? 'Ganti foto'
                      : 'Pilih foto',
                ),
                style: OutlinedButton.styleFrom(foregroundColor: _kGreen1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        const _Judul('Tanggal lahir'),
        _Baris(
          ikon: Icons.cake_outlined,
          nilai: _tanggalLahir == null
              ? null
              : DateFormat('d MMMM yyyy', 'id_ID').format(_tanggalLahir!),
          kosong: 'Belum diisi',
          onTap: _pilihTanggal,
          onHapus: _tanggalLahir == null
              ? null
              : () => setState(() => _tanggalLahir = null),
        ),
        const _Catatan(
          'Tanggal persisnya hanya terlihat oleh Anda dan pengurus. Anggota lain hanya melihat umur.',
        ),
        const SizedBox(height: 24),

        const _Judul('Kontak'),
        TextField(
          controller: _telp,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Nomor telepon',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const _Catatan(
          'Nomor telepon dan email terlihat oleh anggota lain yang sudah terverifikasi, agar kerabat dapat menghubungi Anda. Tidak terlihat oleh publik.',
        ),
        const SizedBox(height: 24),

        const _Judul('Domisili'),
        _Baris(
          ikon: Icons.map_outlined,
          label: 'Provinsi',
          nilai: _provinsi?.name,
          onTap: () => _pilihWilayah('1'),
          onHapus: _provinsi == null ? null : () => _hapusWilayah('1'),
        ),
        _Baris(
          ikon: Icons.location_city_outlined,
          label: 'Kabupaten/Kota',
          nilai: _kabupaten?.name,
          aktif: _provinsi != null,
          onTap: () => _pilihWilayah('2'),
          onHapus: _kabupaten == null ? null : () => _hapusWilayah('2'),
        ),
        _Baris(
          ikon: Icons.holiday_village_outlined,
          label: 'Kecamatan',
          nilai: _kecamatan?.name,
          aktif: _kabupaten != null,
          onTap: () => _pilihWilayah('3'),
          onHapus: _kecamatan == null ? null : () => _hapusWilayah('3'),
        ),
        _Baris(
          ikon: Icons.home_work_outlined,
          label: 'Desa/Kelurahan',
          nilai: _desa?.name,
          aktif: _kecamatan != null,
          onTap: () => _pilihWilayah('4'),
          onHapus: _desa == null ? null : () => _hapusWilayah('4'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _alamat,
          maxLines: 2,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Alamat lengkap (jalan, nomor, RT/RW)',
            border: OutlineInputBorder(),
          ),
        ),
        const _Catatan(
          'Wilayah dan alamat terlihat oleh sesama anggota terverifikasi.',
        ),
        const SizedBox(height: 16),
        _Baris(
          ikon: Icons.pin_drop_outlined,
          label: 'Titik lokasi rumah',
          nilai: _titik == null
              ? null
              : '${_titik!.latitude.toStringAsFixed(5)}, ${_titik!.longitude.toStringAsFixed(5)}',
          kosong: 'Pilih di peta',
          onTap: _pilihTitik,
          onHapus: _titik == null ? null : () => setState(() => _titik = null),
        ),
        _Catatan(
          p.berbagiLokasi
              ? 'Titik ini sedang ditampilkan ke anggota lain di peta Kerabat Terdekat. Untuk mematikannya, ubah di layar Kerabat Terdekat.'
              : 'Titik ini hanya terlihat oleh Anda dan pengurus. Baru tampil di peta Kerabat Terdekat bila Anda menyalakan berbagi lokasi.',
        ),
        const SizedBox(height: 24),

        ..._riwayat(p),

        const _Judul('Lainnya'),
        _Tautan(
          ikon: Icons.edit_note_rounded,
          judul: 'Nama atau hubungan keluarga keliru?',
          keterangan: 'Ajukan usulan, ditinjau pengurus',
          onTap: () => context.push(
            '/usulan/baru',
            extra: {'targetId': p.id, 'targetName': p.name},
          ),
        ),
        const SizedBox(height: 24),

        FilledButton(
          onPressed: _saving ? null : () => _simpan(p),
          style: FilledButton.styleFrom(
            backgroundColor: _kGreen1,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

class _JudulAksi extends StatelessWidget {
  final String teks;
  final VoidCallback onTambah;
  const _JudulAksi({required this.teks, required this.onTambah});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          teks,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _kGreen1,
          ),
        ),
      ),
      TextButton.icon(
        onPressed: onTambah,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Tambah'),
        style: TextButton.styleFrom(foregroundColor: _kGreen1),
      ),
    ],
  );
}

class _BarisRiwayat extends StatelessWidget {
  final IconData ikon;
  final String judul;
  final String keterangan;
  final VoidCallback onHapus;
  const _BarisRiwayat({
    required this.ikon,
    required this.judul,
    required this.keterangan,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(
      backgroundColor: const Color(0x1FC8A24A),
      child: Icon(ikon, color: _kGreen1),
    ),
    title: Text(judul, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: keterangan.isEmpty ? null : Text(keterangan),
    trailing: IconButton(
      icon: const Icon(Icons.delete_outline, color: Colors.red),
      tooltip: 'Hapus',
      onPressed: onHapus,
    ),
  );
}

class _Memuat extends StatelessWidget {
  const _Memuat();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}

class _Judul extends StatelessWidget {
  final String teks;
  const _Judul(this.teks);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      teks,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: _kGreen1,
      ),
    ),
  );
}

class _Catatan extends StatelessWidget {
  final String teks;
  const _Catatan(this.teks);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      teks,
      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
    ),
  );
}

/// Satu baris isian yang membuka pemilih (tanggal / wilayah). Dengan [label],
/// label tampil kecil di atas nilainya; tanpa label, nilainya jadi judul.
class _Baris extends StatelessWidget {
  final IconData ikon;
  final String? label;
  final String? nilai;
  final String kosong;
  final bool aktif;
  final VoidCallback onTap;
  final VoidCallback? onHapus;
  const _Baris({
    required this.ikon,
    required this.onTap,
    this.label,
    this.nilai,
    this.kosong = 'Pilih',
    this.aktif = true,
    this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    final teksNilai = Text(
      nilai ?? (aktif ? kosong : 'Pilih tingkat di atasnya dulu'),
      style: TextStyle(
        fontSize: 15,
        color: nilai == null ? Colors.grey : Colors.black87,
        fontWeight: nilai == null ? FontWeight.w400 : FontWeight.w600,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: aktif ? Colors.white : Colors.grey.shade100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          enabled: aktif,
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          horizontalTitleGap: 12,
          leading: Icon(ikon, color: aktif ? _kGold : Colors.grey),
          title: label == null
              ? teksNilai
              : Text(label!, style: const TextStyle(fontSize: 12)),
          subtitle: label == null ? null : teksNilai,
          trailing: onHapus != null
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Kosongkan',
                  onPressed: onHapus,
                )
              : const Icon(Icons.chevron_right),
          onTap: aktif ? onTap : null,
        ),
      ),
    );
  }
}

class _Tautan extends StatelessWidget {
  final IconData ikon;
  final String judul;
  final String keterangan;
  final VoidCallback onTap;
  const _Tautan({
    required this.ikon,
    required this.judul,
    required this.keterangan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(
      backgroundColor: const Color(0x1FC8A24A),
      child: Icon(ikon, color: _kGreen1),
    ),
    title: Text(judul, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(keterangan),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
