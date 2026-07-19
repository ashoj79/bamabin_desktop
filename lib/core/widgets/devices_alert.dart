import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/data/remote/model/user/device.dart';
import 'package:flutter/material.dart';

class DevicesAlert extends StatelessWidget {
  const DevicesAlert({
    super.key,
    required this.devices,
    required this.onDismiss,
    required this.onClick,
  });

  final List<Device> devices;
  final VoidCallback onDismiss;
  final ValueChanged<int> onClick;

  IconData _iconForType(String type) {
    switch (type) {
      case 'android':
      case 'ios':
        return Icons.phone_iphone_outlined;
      case 'tv':
        return Icons.tv_outlined;
      case 'web':
        return Icons.public_outlined;
      default:
        return Icons.computer_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      backgroundColor: secondaryColor,
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'سقف مجاز استفاده',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'برای ورود به حساب کاربری خود باید از یکی از دستگاه های زیر خارج شوید',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < devices.length; i++)
            TextButton(
              onPressed: () => onClick(i),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Icon(_iconForType(devices[i].type), color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          devices[i].name,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          TextButton(
            onPressed: () => onClick(-1),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                'خارج شدن از همه دستگاه ها',
                style: TextStyle(color: failedColor),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
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
          onClick(index);
          Navigator.of(context).pop();
        },
      );
    },
  );
}
