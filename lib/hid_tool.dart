// Core exports - available on all platforms
export 'src/hid_device.dart';
export 'src/hid_exception.dart';
export 'src/hid_device_events.dart';
export 'src/device_filter.dart';

// Platform implementation exports for plugin registration
// These are conditionally exported based on the target platform
export 'src/platform_imports.dart';

// Import platform interface and Hid class
import 'src/hid_platform_interface.dart';
import 'src/hid_device_events.dart';
import 'src/hid_device.dart';
import 'src/device_filter.dart';

// Import web implementation (uses stub on non-web platforms)
import 'src/web/hid_web.dart' if (dart.library.io) 'src/web/hid_web_stub.dart' as webhid;

class Hid {
  /// Initialize the platform-specific implementation.
  ///
  /// This method is called automatically by [getDevices] and [startListening].
  /// It ensures that the correct platform implementation is registered.
  static void _ensurePlatform() {
    // Platform registration is handled by dart_plugin_registrant.dart
    // which calls the appropriate registerWith() method at startup.
    // This method is kept for potential future use.
  }

  /// Get a list of connected HID devices that match the filters.
  static Future<List<HidDevice>> getDevices({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  }) async {
    _ensurePlatform();
    return HidPlatform.instance.getDevices(
      vendorId: vendorId,
      productId: productId,
      usagePage: usagePage,
      usage: usage,
    );
  }

  /// Start listening for HID device connection/disconnection events.
  static Future<void> startListening() async {
    _ensurePlatform();
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
    List<DeviceFilter>? filters,
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
