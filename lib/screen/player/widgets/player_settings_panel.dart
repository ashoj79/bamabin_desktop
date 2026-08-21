import 'dart:ui';

import 'package:bamabin_desktop/config/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Dark glass settings side panel matching the Figma design.
///
/// Options mirror the mobile sample exactly:
/// - سرعت پخش: 0.75x / 1.0x / 1.25x / 1.5x / 2.0x
/// - رنگ پس زمینه زیرنویس: مشکی / تیره کم‌رنگ / بی‌رنگ
/// - رنگ زیرنویس: سفید / زرد / آبی
/// - فونت: ایران‌سنس / وزیر متن / دانا
/// - اندازه متن: slider 10-72
/// - فاصله زیرنویس از پائین: slider 4-150
class PlayerSettingsPanel extends StatelessWidget {
  const PlayerSettingsPanel({
    super.key,
    required this.subTextColor,
    required this.subBgColor,
    required this.subFont,
    required this.subSize,
    required this.subMargin,
    required this.videoSpeed,
    required this.onSubTextColorSelected,
    required this.onSubBgColorSelected,
    required this.onSubFontSelected,
    required this.onSubSizeChanged,
    required this.onSubMarginChanged,
    required this.onVideoSpeedSelected,
    required this.onReset,
    required this.onClose,
  });

  final int subTextColor;
  final int subBgColor;
  final int subFont;
  final int subSize;
  final int subMargin;
  final int videoSpeed;

  final ValueChanged<int> onSubTextColorSelected;
  final ValueChanged<int> onSubBgColorSelected;
  final ValueChanged<int> onSubFontSelected;
  final ValueChanged<int> onSubSizeChanged;
  final ValueChanged<int> onSubMarginChanged;
  final void Function(int index, double speed) onVideoSpeedSelected;
  final VoidCallback onReset;
  final VoidCallback onClose;

  static const List<String> _speedLabels = [
    '0.75x',
    '1.0x',
    '1.25x',
    '1.5x',
    '2.0x',
  ];
  static const List<double> _speedValues = [0.75, 1.0, 1.25, 1.5, 2.0];

  static const List<String> _bgColorLabels = ['مشکی', 'تیره کم‌رنگ', 'بی‌رنگ'];

  static const List<String> _textColorLabels = ['سفید', 'زرد', 'آبی'];

  static const List<String> _fontLabels = ['ایران‌سنس', 'وزیر متن', 'دانا'];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          bottomLeft: Radius.circular(28),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: const Color(0xCC131321),
            padding: const EdgeInsets.all(32),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(onClose: onClose),
                  _ChipsSection(
                    iconAsset: 'assets/img/player/player_speed.svg',
                    title: 'سرعت پخش',
                    labels: _speedLabels,
                    selectedIndex: videoSpeed,
                    onSelected: (i) =>
                        onVideoSpeedSelected(i, _speedValues[i]),
                  ),
                  _ChipsSection(
                    iconAsset: 'assets/img/player/player_palette.svg',
                    title: 'رنگ پس زمینه زیرنویس',
                    labels: _bgColorLabels,
                    selectedIndex: subBgColor,
                    onSelected: onSubBgColorSelected,
                  ),
                  _ChipsSection(
                    iconAsset: 'assets/img/player/player_palette.svg',
                    title: 'رنگ زیرنویس',
                    labels: _textColorLabels,
                    selectedIndex: subTextColor,
                    onSelected: onSubTextColorSelected,
                  ),
                  _ChipsSection(
                    iconAsset: 'assets/img/player/player_text_size.svg',
                    title: 'فونت',
                    labels: _fontLabels,
                    selectedIndex: subFont,
                    onSelected: onSubFontSelected,
                  ),
                  _SliderSection(
                    iconAsset: 'assets/img/player/player_text_size.svg',
                    title: 'اندازه متن',
                    value: subSize.toDouble(),
                    min: 10,
                    max: 72,
                    onChanged: (v) => onSubSizeChanged(v.round()),
                  ),
                  _SliderSection(
                    iconAsset: 'assets/img/player/player_text_size.svg',
                    title: 'فاصله زیرنویس از پائین',
                    value: subMargin.toDouble(),
                    min: 4,
                    max: 150,
                    isLast: true,
                    onChanged: (v) => onSubMarginChanged(v.round()),
                  ),
                  const SizedBox(height: 8),
                  _ResetButton(onTap: onReset),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Row(
            children: [
              const Text(
                'تنظیمات',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              SvgPicture.asset(
                'assets/img/player/player_settings_outline.svg',
                width: 22,
                height: 22,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
          const Spacer(),
          _CircleIconButton(
            asset: 'assets/img/player/player_panel_close.svg',
            onTap: onClose,
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.asset, required this.onTap});

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x17FFFFFF),
      shape: const CircleBorder(side: BorderSide(color: Color(0x0FFFFFFF))),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: SvgPicture.asset(
              asset,
              width: 18,
              height: 18,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionFrame extends StatelessWidget {
  const _SectionFrame({
    required this.iconAsset,
    required this.title,
    required this.trailing,
    required this.child,
    this.isLast = false,
  });

  final String iconAsset;
  final String title;
  final Widget? trailing;
  final Widget child;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 20, bottom: isLast ? 0 : 4),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x80747775), width: 2)),
      ),
      margin: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                iconAsset,
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ChipsSection extends StatelessWidget {
  const _ChipsSection({
    required this.iconAsset,
    required this.title,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final String iconAsset;
  final String title;
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      iconAsset: iconAsset,
      title: title,
      trailing: null,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(labels.length, (i) {
          return _Chip(
            label: labels[i],
            selected: selectedIndex == i,
            onTap: () => onSelected(i),
          );
        }),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? blueColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x17FFFFFF)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderSection extends StatelessWidget {
  const _SliderSection({
    required this.iconAsset,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.isLast = false,
  });

  final String iconAsset;
  final String title;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      iconAsset: iconAsset,
      title: title,
      isLast: isLast,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: blueColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          value.toInt().toString(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        ),
        child: Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: blueColor,
          thumbColor: blueColor,
          inactiveColor: Colors.white.withValues(alpha: 0.12),
          overlayColor: WidgetStateProperty.all(
            blueColor.withValues(alpha: 0.18),
          ),
        ),
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x14FFFFFF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x17FFFFFF)),
          ),
          alignment: Alignment.center,
          child: const Text(
            'بازنشانی تنظیمات',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
