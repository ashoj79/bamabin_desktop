import 'dart:ui';

import 'package:bamabin_desktop/config/color.dart';
import 'package:flutter/material.dart';

/// Anchored popover menu matching Figma player menus
/// (quality / speed / subtitle / audio).
class PlayerAnchorMenu {
  PlayerAnchorMenu._();

  static const Color _panelBg = Color(0xB2131321); // rgba(19,19,33,0.7)
  static const Color _selectedBg = Color(0x17FFFFFF); // rgba(255,255,255,0.09)
  static const Color _outline = Color(0x17FFFFFF);

  /// Shows a blur popover above [anchorKey]. Returns the selected index, or
  /// `null` if dismissed. When [footerLabel] is set, tapping it returns `-1`.
  static Future<int?> show(
    BuildContext context, {
    required GlobalKey anchorKey,
    required List<String> items,
    required int currentItem,
    String? footerLabel,
    double itemGap = 2,
  }) async {
    final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final anchorOffset = box.localToGlobal(Offset.zero, ancestor: overlay);
    final anchorSize = box.size;
    final screen = overlay.size;

    return showGeneralDialog<int>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return _AnchorMenuOverlay(
          items: items,
          currentItem: currentItem,
          footerLabel: footerLabel,
          itemGap: itemGap,
          anchorOffset: anchorOffset,
          anchorSize: anchorSize,
          screenSize: screen,
          animation: animation,
        );
      },
    );
  }
}

class _AnchorMenuOverlay extends StatelessWidget {
  const _AnchorMenuOverlay({
    required this.items,
    required this.currentItem,
    required this.footerLabel,
    required this.itemGap,
    required this.anchorOffset,
    required this.anchorSize,
    required this.screenSize,
    required this.animation,
  });

  final List<String> items;
  final int currentItem;
  final String? footerLabel;
  final double itemGap;
  final Offset anchorOffset;
  final Size anchorSize;
  final Size screenSize;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    const gapAbove = 8.0;
    const horizontalPad = 8.0;

    final anchorCenterX = anchorOffset.dx + anchorSize.width / 2;
    final alignX = ((anchorCenterX / screenSize.width) * 2 - 1).clamp(
      -1.0,
      1.0,
    );
    final bottom = screenSize.height - anchorOffset.dy + gapAbove;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: horizontalPad,
          right: horizontalPad,
          bottom: bottom,
          child: Align(
            alignment: Alignment(alignX, 1),
            child: FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: screenSize.width - horizontalPad * 2,
                    maxHeight: screenSize.height * 0.55,
                  ),
                  child: _MenuPanel(
                    items: items,
                    currentItem: currentItem,
                    footerLabel: footerLabel,
                    itemGap: itemGap,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuPanel extends StatelessWidget {
  const _MenuPanel({
    required this.items,
    required this.currentItem,
    required this.footerLabel,
    required this.itemGap,
  });

  final List<String> items;
  final int currentItem;
  final String? footerLabel;
  final double itemGap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: PlayerAnchorMenu._panelBg,
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: IntrinsicWidth(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 140),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) SizedBox(height: itemGap),
                      _MenuItem(
                        label: items[i],
                        selected: i == currentItem,
                        outlined: false,
                        onTap: () => Navigator.of(context).pop(i),
                      ),
                    ],
                    if (footerLabel != null) ...[
                      SizedBox(height: itemGap > 2 ? itemGap : 6),
                      _MenuItem(
                        label: footerLabel!,
                        selected: false,
                        outlined: true,
                        onTap: () => Navigator.of(context).pop(-1),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.label,
    required this.selected,
    required this.outlined,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool outlined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        borderRadius: BorderRadius.circular(1000),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? PlayerAnchorMenu._selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(1000),
            border: outlined
                ? Border.all(color: PlayerAnchorMenu._outline)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                height: 16 / 18,
                letterSpacing: -0.12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PlayerResumeAlert {
  PlayerResumeAlert._();

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: const Color(0xFF2B2B2B),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'قبلا در حال تماشای این ویدئو بوده اید. آیا ادامه می دهید؟',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blueColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text(
                        'پخش از ادامه',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(
                        'پخش از ابتدا',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: blueColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    return result ?? false;
  }
}
