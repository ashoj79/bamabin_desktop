import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Set by the player when it enters/exits native fullscreen.
final ValueNotifier<bool> windowNativeFullscreen = ValueNotifier(false);

Future<void> initDesktopWindow() async {
  await windowManager.ensureInitialized();
  const options = WindowOptions(
    backgroundColor: Colors.black,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: 'Bamabin',
    windowButtonVisibility: false,
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.setBrightness(Brightness.dark);
    await windowManager.show();
    await windowManager.focus();
  });
}
