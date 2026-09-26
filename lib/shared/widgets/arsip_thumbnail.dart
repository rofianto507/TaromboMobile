import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

const _kGreen1 = Color(0xFF2E5339);

/// Thumbnail arsip: foto asli untuk jenis='foto' (dari field pratinjau),
/// ikon jenis untuk yang lain — dipakai konsisten di grid & halaman detail.
class ArsipThumbnail extends ConsumerWidget {
  final int arsipId;
  final String jenis;
  final IconData icon;
  final double height;
  final BorderRadius? borderRadius;

  const ArsipThumbnail({
    super.key,
    required this.arsipId,
    required this.jenis,
    required this.icon,
    this.height = 140,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeholder = Container(
      height: height,
      color: const Color(0xFFEFEDE5),
      alignment: Alignment.center,
      child: Icon(icon, size: 40, color: _kGreen1.withValues(alpha: 0.6)),
    );

    if (jenis != 'foto') {
      return ClipRRect(borderRadius: borderRadius ?? BorderRadius.zero, child: placeholder);
    }

    final storage = ref.watch(secureStorageProvider);
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: FutureBuilder<String?>(
        future: kIsWeb ? Future.value(null) : storage.read(key: AppConstants.tokenKey),
        builder: (context, snapshot) {
          if (!kIsWeb && !snapshot.hasData) return placeholder;
          final url = '${AppConfig.baseUrl}/web/image/tarombo.arsip/$arsipId/pratinjau';
          return CachedNetworkImage(
            imageUrl: url,
            httpHeaders: kIsWeb ? const {} : {'Cookie': 'session_id=${snapshot.data}'},
            height: height,
            width: double.infinity,
            fit: BoxFit.contain,
            color: null,
            placeholder: (_, _) => Container(height: height, color: const Color(0xFFEFEDE5)),
            errorWidget: (_, _, _) => placeholder,
            imageBuilder: (context, imageProvider) => Container(
              height: height,
              width: double.infinity,
              color: const Color(0xFFEFEDE5),
              child: Image(image: imageProvider, fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}
