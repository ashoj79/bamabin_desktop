import 'package:bamabin_desktop/config/color.dart';
import 'package:flutter/material.dart';

class DownloadBulkActions extends StatelessWidget {
  const DownloadBulkActions({
    super.key,
    required this.selectionMode,
    required this.hasSelection,
    required this.onToggleSelectionMode,
    required this.onClearSelection,
    required this.onDeleteSelected,
    required this.onSelectAllAndDelete,
  });

  final bool selectionMode;
  final bool hasSelection;
  final VoidCallback onToggleSelectionMode;
  final VoidCallback onClearSelection;
  final VoidCallback onDeleteSelected;
  final VoidCallback onSelectAllAndDelete;

  @override
  Widget build(BuildContext context) {
    // RTL visual order (right → left):
    // انتخاب چندین | پاک کردن | حذف انتخاب‌شده | . | انتخاب همه و حذف
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _ActionTag(
            label: 'انتخاب چندین دانلود',
            foreground: selectionMode
                ? blueColor
                : Colors.white.withValues(alpha: 0.75),
            borderColor: selectionMode
                ? blueColor.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.12),
            onTap: onToggleSelectionMode,
          ),
          if (selectionMode) ...[
            const SizedBox(width: 10),
            _ActionTag(
              label: 'پاک کردن انتخاب شده ها',
              foreground: Colors.white.withValues(alpha: 0.48),
              borderColor: Colors.white.withValues(alpha: 0.12),
              onTap: onClearSelection,
            ),
            const SizedBox(width: 10),
            _ActionTag(
              label: 'حذف دانلود های انتخاب شده',
              foreground: const Color(0xFFF87171),
              borderColor: const Color(0xFFF87171).withValues(alpha: 0.55),
              onTap: hasSelection ? onDeleteSelected : null,
            ),
          ],
          const SizedBox(width: 10),
          Text(
            '.',
            style: TextStyle(
              fontFamily: 'vazir',
              fontSize: 20,
              fontWeight: FontWeight.w500,
              height: 24 / 20,
              color: Colors.white.withValues(alpha: 0.48),
            ),
          ),
          const SizedBox(width: 10),
          _ActionTag(
            label: 'انتخاب همه و حذف دانلود ها',
            foreground: const Color(0xFFF87171),
            borderColor: const Color(0xFFF87171).withValues(alpha: 0.4),
            onTap: onSelectAllAndDelete,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _ActionTag extends StatelessWidget {
  const _ActionTag({
    required this.label,
    required this.foreground,
    this.borderColor,
    this.onTap,
  });

  final String label;
  final Color foreground;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: borderColor != null
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor!),
                )
              : null,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'vazir',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: onTap == null
                  ? foreground.withValues(alpha: 0.35)
                  : foreground,
              height: 24 / 16,
            ),
          ),
        ),
      ),
    );
  }
}
