import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../shared/utils/distance.dart';
import '../../domain/entities/sebaran_wilayah.dart';
import '../providers/nearby_map_provider.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold = Color(0xFFC8A24A);

// Titik tengah bila lokasi perangkat tidak diketahui: sekitar Danau Toba.
const _kDefaultCenter = LatLng(2.6, 99.0);

// Hanya sampai kabupaten/kota: koordinat kecamatan dan desa belum tersedia,
// jadi marker keduanya akan menumpuk di titik kabupaten. Tambahkan kembali
// ('3', 'Kecamatan') dan ('4', 'Desa/Kelurahan') bila koordinatnya sudah ada.
const _tingkatList = [('1', 'Provinsi'), ('2', 'Kabupaten/Kota')];

/// Sebaran anggota: marker per wilayah berisi jumlah anggota yang berdomisili
/// di sana, dengan filter tingkat wilayah. Menggantikan peta "Kerabat
/// Terdekat" yang dulu memakai titik rumah per orang.
class NearbyMapScreen extends ConsumerStatefulWidget {
  const NearbyMapScreen({super.key});

  @override
  ConsumerState<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends ConsumerState<NearbyMapScreen> {
  final _mapController = MapController();
  String _tingkat = '2';
  Position? _posisi;

  @override
  void initState() {
    super.initState();
    _ambilPosisi();
  }

  /// Posisi perangkat hanya dipakai di sisi aplikasi (memusatkan peta dan
  /// mengurutkan wilayah terdekat); tidak pernah dikirim ke server.
  Future<void> _ambilPosisi() async {
    try {
      var izin = await Geolocator.checkPermission();
      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
      }
      if (izin == LocationPermission.denied ||
          izin == LocationPermission.deniedForever) {
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (!mounted) return;
      setState(() => _posisi = pos);
      _mapController.move(LatLng(pos.latitude, pos.longitude), 9);
    } catch (_) {
      // Tanpa lokasi perangkat peta tetap bisa dipakai.
    }
  }

  double? _jarak(TitikWilayah t) {
    if (_posisi == null || !t.punyaTitik) return null;
    return haversineKm(_posisi!.latitude, _posisi!.longitude, t.lat!, t.lng!);
  }

  void _tampilkanDetail(TitikWilayah t) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.nama,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _kGreen1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.namaLengkap,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.groups_rounded, color: _kGold),
                const SizedBox(width: 8),
                Text(
                  '${t.jumlah} anggota',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (t.perkiraan) ...[
              const SizedBox(height: 10),
              Text(
                'Letak di peta diperkirakan dari wilayah induknya.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(sebaranWilayahProvider(_tingkat));

    return Scaffold(
      appBar: AppBar(title: const Text('Sebaran Anggota')),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final (kode, label) in _tingkatList)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _tingkat == kode,
                      selectedColor: _kGold.withValues(alpha: 0.25),
                      labelStyle: TextStyle(
                        color: _tingkat == kode
                            ? _kGreen1
                            : Colors.grey.shade700,
                        fontWeight: _tingkat == kode
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() => _tingkat = kode),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Gagal memuat sebaran anggota. Periksa koneksi Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ),
              data: (data) => _Isi(
                data: data,
                posisi: _posisi,
                controller: _mapController,
                jarak: _jarak,
                onTap: _tampilkanDetail,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Isi extends StatelessWidget {
  final SebaranWilayah data;
  final Position? posisi;
  final MapController controller;
  final double? Function(TitikWilayah) jarak;
  final void Function(TitikWilayah) onTap;

  const _Isi({
    required this.data,
    required this.posisi,
    required this.controller,
    required this.jarak,
    required this.onTap,
  });

  /// Diameter marker membesar landai menurut jumlah (skala log).
  double _ukuran(int jumlah) =>
      34 + 18 * (math.log(jumlah.clamp(1, 1000)) / math.log(1000));

  @override
  Widget build(BuildContext context) {
    final items = [...data.items];
    items.sort((a, b) {
      final ja = jarak(a);
      final jb = jarak(b);
      if (ja != null && jb != null) return ja.compareTo(jb);
      if (ja != null) return -1;
      if (jb != null) return 1;
      return b.jumlah.compareTo(a.jumlah);
    });
    final bertitik = items.where((t) => t.punyaTitik).toList();
    final pusat = posisi != null
        ? LatLng(posisi!.latitude, posisi!.longitude)
        : (bertitik.isNotEmpty
              ? LatLng(bertitik.first.lat!, bertitik.first.lng!)
              : _kDefaultCenter);

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: _kGold.withValues(alpha: 0.12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '${data.totalBerwilayah} dari ${data.totalAnggota} anggota sudah '
            'mengisi domisili pada tingkat ini.',
            style: TextStyle(color: Colors.grey.shade800, fontSize: 12),
          ),
        ),
        Expanded(
          flex: 5,
          child: FlutterMap(
            mapController: controller,
            options: MapOptions(
              initialCenter: pusat,
              initialZoom: posisi != null ? 9 : 7,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'id.selstudio.tarombo_mobile',
              ),
              MarkerLayer(
                markers: [
                  if (posisi != null)
                    Marker(
                      point: LatLng(posisi!.latitude, posisi!.longitude),
                      width: 22,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  for (final t in bertitik)
                    Marker(
                      point: LatLng(t.lat!, t.lng!),
                      width: _ukuran(t.jumlah),
                      height: _ukuran(t.jumlah),
                      child: GestureDetector(
                        onTap: () => onTap(t),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _kGreen1,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: t.perkiraan ? _kGold : Colors.white,
                              width: 2.5,
                            ),
                            boxShadow: const [
                              BoxShadow(blurRadius: 4, color: Colors.black26),
                            ],
                          ),
                          child: Text(
                            '${t.jumlah}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Belum ada anggota yang mengisi domisili pada tingkat ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final t = items[i];
                    final km = jarak(t);
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: _kGreen1,
                        child: Text(
                          '${t.jumlah}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(t.nama),
                      subtitle: Text(
                        [
                          t.namaLengkap,
                          if (km != null) '${km.toStringAsFixed(0)} km',
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        if (t.punyaTitik) {
                          controller.move(LatLng(t.lat!, t.lng!), 10);
                        }
                        onTap(t);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
