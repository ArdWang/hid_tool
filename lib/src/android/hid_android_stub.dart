/// Stub implementation for non-Android platforms.

import 'package:hid_tool/src/hid_platform_interface.dart';
import 'package:hid_tool/src/hid_device.dart';

/// Stub implementation of HidAndroid for non-Android platforms.
class HidAndroid extends HidPlatform {
  static void registerWith() {
    throw UnsupportedError('HidAndroid is only available on Android');
  }

  @override
  Future<List<HidDevice>> getDevices({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  }) {
    throw UnsupportedError('HidAndroid is only available on Android');
  }
}
