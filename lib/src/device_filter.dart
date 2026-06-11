/// Device filter for WebHID.
///
/// This file contains only pure Dart code, no web-specific imports.
/// It can be safely imported on all platforms.

/// Device filter for WebHID device requests.
class DeviceFilter {
  /// USB Vendor ID (VID) to filter by.
  final int? vendorId;

  /// USB Product ID (PID) to filter by.
  final int? productId;

  /// HID Usage Page to filter by.
  final int? usagePage;

  /// HID Usage to filter by.
  final int? usage;

  /// Creates a device filter for WebHID device requests.
  ///
  /// All parameters are optional. If no filters are specified,
  /// all devices will be shown in the permission dialog.
  DeviceFilter({
    this.vendorId,
    this.productId,
    this.usagePage,
    this.usage,
  });
}
