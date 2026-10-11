import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceName {
  DeviceName._();

  static final DeviceInfoPlugin _plugin = DeviceInfoPlugin();
  static String? _cached;

  static Future<String> current() async {
    if (_cached != null) return _cached!;
    try {
      if (kIsWeb) {
        final info = await _plugin.webBrowserInfo;
        return _cached = _clean(info.browserName.name);
      }
      if (Platform.isAndroid) {
        final info = await _plugin.androidInfo;
        return _cached = _clean(
          [info.manufacturer, info.model]
              .where((v) => v.trim().isNotEmpty)
              .join(' '),
        );
      }
      if (Platform.isIOS) {
        final info = await _plugin.iosInfo;
        final machine = info.utsname.machine;
        return _cached = _clean(_appleModelName(machine) ??
            (machine.isNotEmpty ? machine : info.model));
      }
      if (Platform.isWindows) {
        final info = await _plugin.windowsInfo;
        return _cached = _clean(info.computerName.isNotEmpty
            ? info.computerName
            : 'Windows device');
      }
      if (Platform.isMacOS) {
        final info = await _plugin.macOsInfo;
        return _cached =
            _clean(info.computerName.isNotEmpty ? info.computerName : 'Mac');
      }
      if (Platform.isLinux) {
        final info = await _plugin.linuxInfo;
        return _cached = _clean(
            info.prettyName.isNotEmpty ? info.prettyName : 'Linux device');
      }
    } catch (_) {
      // Fall through to a stable app-level label.
    }
    return _cached = 'CityCalls Mobile App';
  }

  static String _clean(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    return normalized.isEmpty ? 'CityCalls Mobile App' : normalized;
  }

  static String? _appleModelName(String machine) {
    const models = {
      'iPhone14,4': 'iPhone 13 mini',
      'iPhone14,5': 'iPhone 13',
      'iPhone14,2': 'iPhone 13 Pro',
      'iPhone14,3': 'iPhone 13 Pro Max',
      'iPhone14,7': 'iPhone 14',
      'iPhone14,8': 'iPhone 14 Plus',
      'iPhone15,2': 'iPhone 14 Pro',
      'iPhone15,3': 'iPhone 14 Pro Max',
      'iPhone15,4': 'iPhone 15',
      'iPhone15,5': 'iPhone 15 Plus',
      'iPhone16,1': 'iPhone 15 Pro',
      'iPhone16,2': 'iPhone 15 Pro Max',
      'iPhone17,3': 'iPhone 16',
      'iPhone17,4': 'iPhone 16 Plus',
      'iPhone17,1': 'iPhone 16 Pro',
      'iPhone17,2': 'iPhone 16 Pro Max',
      'iPad13,16': 'iPad Air',
      'iPad13,17': 'iPad Air',
      'iPad14,3': 'iPad Pro 11-inch',
      'iPad14,4': 'iPad Pro 11-inch',
      'iPad14,5': 'iPad Pro 12.9-inch',
      'iPad14,6': 'iPad Pro 12.9-inch',
    };
    return models[machine];
  }
}
