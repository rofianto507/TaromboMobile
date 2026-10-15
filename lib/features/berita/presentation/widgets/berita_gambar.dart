import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const _kGreen1 = Color(0xFF2E5339);

/// Gambar sampul berita/agenda dari /web/image (sesi login dikirim lewat
/// cookie). Tanpa gambar tampil latar hijau dengan ikon jenisnya.
class BeritaGambar extends ConsumerWidget {
  final int beritaId;
  final bool punyaGambar;
  final bool agenda;
  final double? height;
  final BorderRadius borderRadius;

  const BeritaGambar({
    super.key,
    required this.beritaId,
    required this.punyaGambar,
    required this.agenda,
    this.height,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeholder = Container(
      height: height,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kGreen1, _kGreen1.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        agenda ? Icons.event_rounded : Icons.newspaper_rounded,
        size: 40,
        color: Colors.white.withValues(alpha: 0.85),
      ),
    );
    if (!punyaGambar) {
      return ClipRRect(borderRadius: borderRadius, child: placeholder);
    }

    final storage = ref.watch(secureStorageProvider);
    return ClipRRect(
      borderRadius: borderRadius,
      child: FutureBuilder<String?>(
        future: kIsWeb
            ? Future.value(null)
            : storage.read(key: AppConstants.tokenKey),
        builder: (context, snap) {
          if (!kIsWeb && !snap.hasData) return placeholder;
          return CachedNetworkImage(
            imageUrl:
                '${AppConfig.baseUrl}/web/image/tarombo.berita/$beritaId/gambar',
            httpHeaders: kIsWeb
                ? const {}
                : {'Cookie': 'session_id=${snap.data}'},
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, _) => placeholder,
            errorWidget: (_, _, _) => placeholder,
          );
        },
      ),
    );
  }
}
