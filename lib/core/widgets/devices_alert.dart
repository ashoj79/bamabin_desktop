import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/data/remote/model/user/device.dart';
import 'package:flutter/material.dart';

ButtonStyle _deviceButtonStyle(BuildContext context) {
  final primary = Theme.of(context).colorScheme.primary;
  return ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused) ||
          states.contains(WidgetState.hovered)) {
        return primary;
      }
      return Colors.white;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused) ||
          states.contains(WidgetState.hovered)) {
        return Colors.white;
      }
      return Colors.black;
    }),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    minimumSize: WidgetStateProperty.all(const Size(double.infinity, 48)),
    elevation: WidgetStateProperty.all(0),
  );
}

ButtonStyle _logoutAllButtonStyle() {
  return ButtonStyle(
    backgroundColor: WidgetStateProperty.all(failedColor),
    foregroundColor: WidgetStateProperty.all(Colors.white),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    minimumSize: WidgetStateProperty.all(const Size(double.infinity, 48)),
    elevation: WidgetStateProperty.all(0),
  );
}

class DevicesAlert extends StatelessWidget {
  const DevicesAlert({
    super.key,
    required this.devices,
    required this.onDismiss,
    required this.onClick,
  });

  final List<Device> devices;
  final VoidCallback onDismiss;

  /// Index of the device to remove, or `-1` to remove all devices.
  final ValueChanged<int> onClick;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
    );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
    );
    final buttonTextStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: Colors.black,
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: const Color(0xFF2B2B2B),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    'سقف مجاز استفاده',
                    style: titleStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: IconButton(
                    onPressed: onDismiss,
                    icon: Icon(Icons.cancel_outlined, color: failedColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'برای ورود به حساب کاربری خود باید از یکی از دستگاه های زیر خارج شوید',
              style: bodyStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < devices.length; i++) ...[
                      if (i > 0) const SizedBox(height: 16),
                      ElevatedButton(
                        style: _deviceButtonStyle(context),
                        onPressed: () => onClick(i),
                        child: Text(
                          devices[i].name,
                          textAlign: TextAlign.center,
                          style: buttonTextStyle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: _logoutAllButtonStyle(),
              onPressed: () => onClick(-1),
              child: Text(
                'خروج از همه دستگاه ها',
                textAlign: TextAlign.center,
                style: buttonTextStyle?.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showDevicesAlert(
  BuildContext context, {
  required List<Device> devices,
  required ValueChanged<int> onClick,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return DevicesAlert(
        devices: devices,
        onDismiss: () => Navigator.of(context).pop(),
        onClick: (index) {
          Navigator.of(context).pop();
          onClick(index);
        },
      );
    },
  );
}
