import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold   = Color(0xFFC8A24A);

// Titik tengah default kalau belum ada titik awal & izin lokasi ditolak:
// sekitar Danau Toba/Silaen (sama seperti peta Kerabat Terdekat).
const _kDefaultCenter = LatLng(2.6, 99.0);

/// Peta interaktif untuk memilih SATU titik koordinat — dipakai form Usulan
/// (usul_latitude/usul_longitude). Pola "pin tetap di tengah layar, peta yang
/// digeser di baliknya" dipilih karena jauh lebih stabil di Flutter daripada
/// marker yang di-drag langsung (tidak perlu urus gesture conflict dengan
/// pan/zoom peta itu sendiri) — mirip pengalaman widget tarombo_geo_picker
/// di backend.
///
/// Return `LatLng` yang dipilih, atau `null` kalau dibatalkan.
class LokasiPickerScreen extends StatefulWidget {
  final LatLng? titikAwal;
  const LokasiPickerScreen({super.key, this.titikAwal});

  @override
  State<LokasiPickerScreen> createState() => _LokasiPickerScreenState();
}

class _LokasiPickerScreenState extends State<LokasiPickerScreen> {
  final _mapController = MapController();
  late LatLng _center;
  bool _mencariGps = false;

  @override
  void initState() {
    super.initState();
    _center = widget.titikAwal ?? _kDefaultCenter;
    if (widget.titikAwal == null) _pakaiGpsSaatIni();
  }

  Future<void> _pakaiGpsSaatIni() async {
    setState(() => _mencariGps = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium));
      if (!mounted) return;
      final target = LatLng(pos.latitude, pos.longitude);
      setState(() => _center = target);
      _mapController.move(target, 15);
    } catch (_) {
      // Biarkan di titik default — bukan alur wajib.
    } finally {
      if (mounted) setState(() => _mencariGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Titik Lokasi'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _center),
            child: const Text('Pilih', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13,
              onPositionChanged: (pos, _) => _center = pos.center,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'id.selstudio.tarombo_mobile',
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 36),
            child: Icon(Icons.location_on, color: _kGreen1, size: 48),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)]),
              child: const Text('Geser peta sampai pin tepat di titik yang dimaksud', style: TextStyle(fontSize: 12)),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 24,
            child: FloatingActionButton.small(
              backgroundColor: _kGold,
              foregroundColor: _kGreen1,
              onPressed: _mencariGps ? null : _pakaiGpsSaatIni,
              child: _mencariGps
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
