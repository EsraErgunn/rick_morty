import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';

/// İsteğe bağlı sağa hizalı bir değeri (SPEC §5.6) ve devre dışıyken isteğe bağlı
/// bir ipucu olan, sola hizalı tek bir menü satırı.
class MenuEntry extends StatelessWidget {
  const MenuEntry({
    required this.label,
    required this.onTap,
    this.value,
    this.hint,
    super.key,
  });

  final String label;

  /// Null = devre dışı.
  final VoidCallback? onTap;
  final String? value;

  /// Devre dışıyken etiketin altında gösterilir (ör. "Destene 3 kart ekle").
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final labelStyle = AppTypography.headline.copyWith(
      color: enabled ? AppColors.paper : AppColors.paperMuted,
    );
    return Semantics(
      button: true,
      enabled: enabled,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.buttonAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: labelStyle),
                    if (!enabled && hint != null)
                      Text(hint!, style: AppTypography.caption),
                  ],
                ),
              ),
              if (value != null) Text(value!, style: AppTypography.stat),
            ],
          ),
        ),
      ),
    );
  }
}
