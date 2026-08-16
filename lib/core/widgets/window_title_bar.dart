import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/window_chrome.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowTitleBar extends StatefulWidget {
  const WindowTitleBar({super.key});

  @override
  State<WindowTitleBar> createState() => _WindowTitleBarState();
}

class _WindowTitleBarState extends State<WindowTitleBar> with WindowListener {
  bool _isMaximized = false;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowNativeFullscreen.addListener(_rebuild);
    _syncWindowState();
  }

  @override
  void dispose() {
    windowNativeFullscreen.removeListener(_rebuild);
    windowManager.removeListener(this);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _syncWindowState() async {
    final maximized = await windowManager.isMaximized();
    final fullScreen = await windowManager.isFullScreen();
    if (!mounted) return;
    setState(() {
      _isMaximized = maximized;
      _isFullScreen = fullScreen;
    });
  }

  @override
  void onWindowMaximize() => _syncWindowState();

  @override
  void onWindowUnmaximize() => _syncWindowState();

  @override
  void onWindowEnterFullScreen() => _syncWindowState();

  @override
  void onWindowLeaveFullScreen() => _syncWindowState();

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen || windowNativeFullscreen.value) {
      return const SizedBox.shrink();
    }

    return ColoredBox(
      color: Colors.black,
      child: SizedBox(
        height: kWindowCaptionHeight,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              Expanded(
                child: DragToMoveArea(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'بامابین',
                        style: TextStyle(
                          fontFamily: 'dana',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: desktopInkColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _CaptionButton(
                tooltip: 'کوچک کردن',
                child: WindowCaptionButton.minimize(
                  brightness: Brightness.dark,
                  onPressed: () async {
                    final minimized = await windowManager.isMinimized();
                    if (minimized) {
                      await windowManager.restore();
                    } else {
                      await windowManager.minimize();
                    }
                  },
                ),
              ),
              _CaptionButton(
                tooltip: _isMaximized ? 'بازگردانی' : 'بزرگ کردن',
                child: _isMaximized
                    ? WindowCaptionButton.unmaximize(
                        brightness: Brightness.dark,
                        onPressed: windowManager.unmaximize,
                      )
                    : WindowCaptionButton.maximize(
                        brightness: Brightness.dark,
                        onPressed: windowManager.maximize,
                      ),
              ),
              _CaptionButton(
                tooltip: 'بستن',
                child: WindowCaptionButton.close(
                  brightness: Brightness.dark,
                  onPressed: windowManager.close,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptionButton extends StatelessWidget {
  const _CaptionButton({required this.tooltip, required this.child});

  final String tooltip;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      preferBelow: true,
      verticalOffset: 16,
      child: child,
    );
  }
}
