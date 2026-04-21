/// Stub implementation for non-web platforms.

import '../hid_device.dart';
import '../hid_platform_interface.dart';
import '../device_filter.dart';

/// Stub implementation of HidWeb for non-web platforms.
class HidWeb extends HidPlatform {
  /// Returns false on non-web platforms.
  static bool get isSupported => false;

  @override
  Future<List<HidDevice>> getDevices({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  }) {
    throw UnsupportedError('WebHID is only available on Web');
  }

  /// Request device access (Web only).
  Future<List<HidDevice>> requestDevice({
    List<DeviceFilter>? filters,
  }) {
    throw UnsupportedError('requestDevice is only available on Web');
  }
}
