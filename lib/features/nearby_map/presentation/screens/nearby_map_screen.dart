import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../shared/utils/distance.dart';
import '../../../../shared/utils/orang_labels.dart';
import '../../../klaim/domain/entities/klaim_info.dart';
import '../../../klaim/presentation/providers/klaim_provider.dart';
import '../../domain/entities/kerabat_lokasi.dart';
import '../providers/nearby_map_provider.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold   = Color(0xFFC8A24A);

// Titik tengah default kalau izin lokasi ditolak: sekitar Danau Toba/Silaen.
const _kDefaultCenter = LatLng(2.6, 99.0);

class NearbyMapScreen extends ConsumerStatefulWidget {
  const NearbyMapScreen({super.key});

  @override
  ConsumerState<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends ConsumerState<NearbyMapScreen> {
  final _mapController = MapController();
  Position? _myPosition;
  bool _locationDenied = false;
  bool _togglingBerbagi = false;
  String? _toggleError;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _locationDenied = true);
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _locationDenied = true);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium));
      if (mounted) setState(() => _myPosition = pos);
    } catch (_) {
      if (mounted) setState(() => _locationDenied = true);
    }
  }

  Future<void> _toggleBerbagi(bool value) async {
    setState(() {
      _togglingBerbagi = true;
      _toggleError = null;
    });
    try {
      final service = ref.read(berbagiLokasiServiceProvider);
      if (value) {
        final pos = _myPosition ?? await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium));
        _myPosition = pos;
        await service.aktifkan(pos.latitude, pos.longitude);
      } else {
        await service.nonaktifkan();
      }
    } catch (e) {
      setState(() => _toggleError = 'Gagal mengubah pengaturan. Pastikan GPS aktif dan coba lagi.');
    } finally {
      if (mounted) setState(() => _togglingBerbagi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kerabatAsync = ref.watch(kerabatLokasiProvider);
    final myOrang = ref.watch(klaimNotifierProvider).valueOrNull?.orang;

    return Scaffold(
      appBar: AppBar(title: const Text('Kerabat Terdekat')),
      body: kerabatAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat data peta.\n$e', textAlign: TextAlign.center)),
        data: (kerabat) {
          for (final k in kerabat) {
            if (_myPosition != null) {
              k.jarakKm = haversineKm(_myPosition!.latitude, _myPosition!.longitude, k.lat, k.lng);
            }
          }
          final sorted = [...kerabat]..sort((a, b) => (a.jarakKm ?? 1e9).compareTo(b.jarakKm ?? 1e9));
          final center = _myPosition != null
              ? LatLng(_myPosition!.latitude, _myPosition!.longitude)
              : (kerabat.isNotEmpty ? LatLng(kerabat.first.lat, kerabat.first.lng) : _kDefaultCenter);

          return Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(initialCenter: center, initialZoom: _myPosition != null ? 11 : 8),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'id.selstudio.tarombo_mobile',
                        ),
                        MarkerLayer(
                          markers: [
                            if (_myPosition != null)
                              Marker(
                                point: LatLng(_myPosition!.latitude, _myPosition!.longitude),
                                width: 24,
                                height: 24,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                                  ),
                                ),
                              ),
                            for (final k in kerabat)
                              Marker(
                                point: LatLng(k.lat, k.lng),
                                width: 40,
                                height: 40,
                                child: GestureDetector(
                                  onTap: () => _showKerabatSheet(context, k),
                                  child: Icon(
                                    Icons.location_on,
                                    color: k.jenisKelamin == 'P' ? Colors.pink.shade400 : _kGreen1,
                                    size: 40,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    if (_locationDenied)
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                          child: const Text(
                            'Izin lokasi tidak diberikan — jarak ke kerabat tidak bisa dihitung.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (kerabat.isNotEmpty)
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: sorted.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final k = sorted[i];
                      return _KerabatChip(
                        kerabat: k,
                        onTap: () {
                          _mapController.move(LatLng(k.lat, k.lng), 13);
                          _showKerabatSheet(context, k);
                        },
                      );
                    },
                  ),
                ),
              _buildBerbagiCard(myOrang),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBerbagiCard(MyOrang? myOrang) {
    final aktif = myOrang?.berbagiLokasi == true;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _kGreen1, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.share_location_rounded, color: _kGold, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Bagikan lokasi saya ke kerabat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                _togglingBerbagi
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Switch(
                        value: aktif,
                        activeTrackColor: _kGold,
                        onChanged: myOrang == null ? null : _toggleBerbagi,
                      ),
              ],
            ),
            Text(
              myOrang == null
                  ? 'Klaim identitas Anda dulu untuk bisa membagikan lokasi.'
                  : aktif
                      ? 'Titik lokasi Anda terlihat oleh seluruh anggota di peta ini.'
                      : 'Nonaktif — lokasi Anda tidak ditampilkan ke siapa pun.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
            ),
            if (_toggleError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_toggleError!, style: const TextStyle(color: Colors.orangeAccent, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }

  void _showKerabatSheet(BuildContext context, KerabatLokasi k) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kGreen1)),
            const SizedBox(height: 6),
            Text(
              'Sundut ${k.sundut} • ${jenisKelaminLabel(k.jenisKelamin)}${k.punguan != null ? ' • ${k.punguan}' : ''}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (k.jarakKm != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.social_distance_rounded, size: 16, color: _kGold),
                  const SizedBox(width: 6),
                  Text('${formatDistanceKm(k.jarakKm!)} dari lokasi Anda', style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _kGold, foregroundColor: _kGreen1),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/profil/${k.id}');
                },
                child: const Text('Lihat Profil'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KerabatChip extends StatelessWidget {
  final KerabatLokasi kerabat;
  final VoidCallback onTap;
  const _KerabatChip({required this.kerabat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(kerabat.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _kGreen1)),
            const SizedBox(height: 2),
            Text(
              kerabat.jarakKm != null ? formatDistanceKm(kerabat.jarakKm!) : 'Sundut ${kerabat.sundut}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
