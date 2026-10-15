import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/sebaran_wilayah.dart';

/// Jumlah anggota per wilayah pada satu tingkat ('1' provinsi, '2' kabupaten/
/// kota, '3' kecamatan, '4' desa/kelurahan). Hanya agregat, tanpa data individu.
final sebaranWilayahProvider = FutureProvider.autoDispose
    .family<SebaranWilayah, String>((ref, tingkat) async {
      final api = ref.read(apiClientProvider);
      final json =
          await api.callKw(
                model: 'tarombo.orang',
                method: 'get_sebaran_wilayah',
                args: [tingkat],
              )
              as Map;
      return SebaranWilayah.fromJson(json.cast<String, dynamic>());
    });
