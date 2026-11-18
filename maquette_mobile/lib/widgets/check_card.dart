import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CheckCard extends StatelessWidget {
  const CheckCard({
    super.key,
    required this.label,
    required this.checked,
    required this.onChanged,
    this.trailing,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool>? onChanged; // null = case verrouillée
  final String? trailing; // ex. « Obligatoire »

  @override
  Widget build(BuildContext context) {
    return Material(
      color: checked ? AppColors.mint : Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: checked ? AppColors.green : AppColors.border,
          width: checked ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!checked),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Checkbox(
                value: checked,
                onChanged:
                    onChanged == null ? null : (v) => onChanged!(v ?? false),
                activeColor: AppColors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(color: Color(0xFF8A938D), width: 1.5),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}