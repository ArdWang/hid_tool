/// Stub implementation for non-web platforms.

import '../hid_device.dart';
import '../hid_platform_interface.dart';

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

/// Device filter for WebHID.
class DeviceFilter {
  final int? vendorId;
  final int? productId;
  final int? usagePage;
  final int? usage;

  DeviceFilter({
    this.vendorId,
    this.productId,
    this.usagePage,
    this.usage,
  });
}
