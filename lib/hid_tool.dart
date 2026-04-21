// Core exports - available on all platforms
export 'src/hid_device.dart';
export 'src/hid_exception.dart';
export 'src/hid_device_events.dart';

// Export Web-specific types (stub on non-web)
export 'src/web/hid_web.dart' show DeviceFilter;

// Import platform interface and Hid class
import 'src/hid_platform_interface.dart';
import 'src/hid_device_events.dart';
import 'src/hid_device.dart';

// Import web implementation (uses stub on non-web platforms)
import 'src/web/hid_web.dart' if (dart.library.io) 'src/web/hid_web_stub.dart' as webhid;

class Hid {
  /// Get a list of connected HID devices that match the filters.
  static Future<List<HidDevice>> getDevices({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  }) async {
    return HidPlatform.instance.getDevices(
      vendorId: vendorId,
      productId: productId,
      usagePage: usagePage,
      usage: usage,
    );
  }

  /// Start listening for HID device connection/disconnection events.
  static Future<void> startListening() async {
    await HidPlatform.instance.startListening();
    await HidDeviceEvents.startListening();
  }

  /// Stop listening for HID device events.
  static Future<void> stopListening() async {
    await HidDeviceEvents.stopListening();
    await HidPlatform.instance.stopListening();
  }

  /// Request device access from the user (Web only).
  static Future<List<HidDevice>> requestDevice({
    List<webhid.DeviceFilter>? filters,
  }) async {
    if (!webhid.HidWeb.isSupported) {
      throw UnsupportedError('requestDevice is only available on Web');
    }

    final webPlatform = HidPlatform.instance as webhid.HidWeb;
    return webPlatform.requestDevice(filters: filters);
  }

  /// Check if WebHID is supported (Web only).
  static bool get isWebHIDSupported => webhid.HidWeb.isSupported;
}
