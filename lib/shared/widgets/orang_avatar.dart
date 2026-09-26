import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

const _kGold   = Color(0xFFC8A24A);
const _kGreen1 = Color(0xFF2E5339);

/// Foto profil tarombo.orang, diambil dari /web/image/ standar Odoo.
/// Fallback ke ikon kalau orang belum punya foto atau gagal dimuat.
class OrangAvatar extends ConsumerWidget {
  final int orangId;
  final double radius;
  final String jenisKelamin;

  const OrangAvatar({super.key, required this.orangId, required this.jenisKelamin, this.radius = 24});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(secureStorageProvider);
    final fallbackIcon = jenisKelamin == 'P' ? Icons.woman_rounded : Icons.man_rounded;

    return FutureBuilder<String?>(
      future: kIsWeb ? Future.value(null) : storage.read(key: AppConstants.tokenKey),
      builder: (context, snapshot) {
        if (!kIsWeb && !snapshot.hasData) {
          return CircleAvatar(radius: radius, backgroundColor: _kGold.withValues(alpha: 0.15), child: Icon(fallbackIcon, color: _kGreen1));
        }
        final url = '${AppConfig.baseUrl}/web/image/tarombo.orang/$orangId/foto';
        return ClipOval(
          child: CachedNetworkImage(
            imageUrl: url,
            httpHeaders: kIsWeb ? const {} : {'Cookie': 'session_id=${snapshot.data}'},
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (_, _) => CircleAvatar(radius: radius, backgroundColor: _kGold.withValues(alpha: 0.15)),
            errorWidget: (_, _, _) => CircleAvatar(radius: radius, backgroundColor: _kGold.withValues(alpha: 0.15), child: Icon(fallbackIcon, color: _kGreen1)),
          ),
        );
      },
    );
  }
}
