import 'dart:io';

import 'package:win32_registry/win32_registry.dart';

Future<void> registerBamabinWindowsProtocol() async {
  if (!Platform.isWindows) return;

  final appPath = Platform.resolvedExecutable;
  const protocolRegKey = r'Software\Classes\bamabin';
  const protocolCmdRegKey = r'shell\open\command';

  final regKey = Registry.currentUser.createKey(protocolRegKey);
  regKey.createValue(const RegistryValue.string('URL Protocol', ''));
  regKey.createValue(
    const RegistryValue.string('', 'URL:Bamabin Protocol'),
  );
  regKey.createKey(protocolCmdRegKey).createValue(
    RegistryValue.string('', '"$appPath" "%1"'),
  );
}
