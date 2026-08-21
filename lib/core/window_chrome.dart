import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Set by the player when it enters/exits native fullscreen.
final ValueNotifier<bool> windowNativeFullscreen = ValueNotifier(false);

Future<void> initDesktopWindow() async {
  await windowManager.ensureInitialized();
  const options = WindowOptions(
    size: Size(1280, 720),
    center: true,
    backgroundColor: Color(0xFF121216),
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: 'Bamabin',
    windowButtonVisibility: false,
  );
  // Show only after Flutter has produced a frame (see BootstrapApp).
  windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.setBrightness(Brightness.dark);
    await windowManager.show();
    await windowManager.maximize();
    await windowManager.focus();
  });
}

Future<void> ensureDesktopWindowVisible() async {
  try {
    if (!await windowManager.isVisible()) {
      await windowManager.show();
    }
    if (!await windowManager.isMaximized()) {
      await windowManager.maximize();
    }
    await windowManager.focus();
  } catch (_) {}
}
