import 'package:flutter/material.dart';

class DownloadStatsRow extends StatelessWidget {
  const DownloadStatsRow({
    super.key,
    required this.allCount,
    required this.activeCount,
    required this.completedCount,
    required this.pausedCount,
    required this.errorCount,
  });

  final int allCount;
  final int activeCount;
  final int completedCount;
  final int pausedCount;
  final int errorCount;

  @override
  Widget build(BuildContext context) {
    // RTL visual order (right → left): فعال، تکمیل، متوقف، خطا، همه
    final items = [
      ('فعال', activeCount),
      ('تکمیل', completedCount),
      ('متوقف', pausedCount),
      ('خطا', errorCount),
      ('همه', allCount),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _StatCard(label: items[i].$1, count: items[i].$2),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF131321).withValues(alpha: 0.8),
            const Color(0xFF131321).withValues(alpha: 0.48),
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w500,
              height: 48 / 32,
              letterSpacing: -0.3,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 22 / 16,
              letterSpacing: -0.18,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
