import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/screen/download_manager/bloc/download_manager_event.dart';
import 'package:flutter/material.dart';

class DownloadFilterBar extends StatelessWidget {
  const DownloadFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final DownloadFilter selected;
  final ValueChanged<DownloadFilter> onChanged;

  static const _items = <(DownloadFilter, String)>[
    (DownloadFilter.error, 'خطا'),
    (DownloadFilter.paused, 'متوقف'),
    (DownloadFilter.completed, 'تکمیل'),
    (DownloadFilter.active, 'فعال'),
    (DownloadFilter.all, 'همه'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(
            child: _FilterPill(
              label: _items[i].$2,
              selected: selected == _items[i].$1,
              onTap: () => onChanged(_items[i].$1),
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? blueColor : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.09),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: selected
                  ? const Color(0xFF0C0C14)
                  : Colors.white.withValues(alpha: 0.75),
              letterSpacing: -0.18,
            ),
          ),
        ),
      ),
    );
  }
}
