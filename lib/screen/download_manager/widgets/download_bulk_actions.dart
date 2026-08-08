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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (selectionMode) ...[
            _ActionTag(
              label: 'پاک کردن انتخاب شده ها',
              foreground: Colors.white.withValues(alpha: 0.48),
              onTap: onClearSelection,
            ),
            _ActionTag(
              label: 'حذف دانلود های انتخاب شده',
              foreground: failedColor,
              borderColor: failedColor.withValues(alpha: 0.5),
              onTap: hasSelection ? onDeleteSelected : null,
            ),
          ],
          _ActionTag(
            label: 'انتخاب همه و حذف دانلود ها',
            foreground: failedColor,
            onTap: onSelectAllAndDelete,
          ),
          Text(
            '.',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white.withValues(alpha: 0.48),
            ),
          ),
          _ActionTag(
            label: 'انتخاب چندین دانلود',
            foreground: selectionMode ? blueColor : Colors.white.withValues(alpha: 0.75),
            borderColor: selectionMode
                ? blueColor.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.12),
            onTap: onToggleSelectionMode,
          ),
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
