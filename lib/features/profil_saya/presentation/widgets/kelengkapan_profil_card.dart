import 'package:flutter/material.dart';
import '../../domain/entities/profil_saya.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold = Color(0xFFC8A24A);

/// Kartu "Profil Anda N% lengkap". Ringkas (beranda): persentase, batang,
/// dan satu ajakan langkah berikutnya. [rinci] (form): daftar centang tiap butir.
class KelengkapanProfilCard extends StatelessWidget {
  final KelengkapanProfil kelengkapan;
  final bool rinci;
  final VoidCallback? onTap;
  const KelengkapanProfilCard({
    super.key,
    required this.kelengkapan,
    this.rinci = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final k = kelengkapan;
    final berikutnya = k.berikutnya;
    return Material(
      color: Colors.white,
      elevation: rinci ? 0 : 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: rinci ? Colors.grey.shade300 : Colors.transparent),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      k.lengkap ? 'Profil Anda sudah lengkap' : 'Profil Anda ${k.persen}% lengkap',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _kGreen1,
                      ),
                    ),
                  ),
                  if (onTap != null) const Icon(Icons.chevron_right_rounded, color: _kGreen1),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: k.persen / 100,
                  minHeight: 8,
                  backgroundColor: _kGold.withValues(alpha: 0.18),
                  valueColor: const AlwaysStoppedAnimation(_kGold),
                ),
              ),
              if (!rinci && berikutnya != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Berikutnya: ${berikutnya.label}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
              if (rinci) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    for (final b in k.butir)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            b.selesai
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 16,
                            color: b.selesai ? _kGreen1 : Colors.grey,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            b.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: b.selesai ? Colors.black87 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
