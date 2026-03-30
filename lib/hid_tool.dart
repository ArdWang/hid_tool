export 'src/hid_device.dart';
export 'src/hid_exception.dart';
export 'src/hid_device_events.dart';

import 'src/hid_device.dart';
import 'src/hid_platform_interface.dart';
import 'src/hid_device_events.dart';
export 'src/android/hid_android.dart';
export 'src/desktop/hid_desktop.dart';

class Hid {
  /// Get a list of connected HID devices that match the
  /// filters passed in. If no filter is provided get all
  /// connected devices.
  ///
  /// Example usage:
  /// ```dart
  /// List<HidDevice> devices = await getDevices(vendorId: 0x25, productId: 0x26);
  /// ```
  static Future<List<HidDevice>> getDevices({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  }) {
    return HidPlatform.instance.getDevices(
      vendorId: vendorId,
      productId: productId,
      usagePage: usagePage,
      usage: usage,
    );
  }

  /// Start listening for HID device connection/disconnection events.
  ///
  /// This method enables the platform-specific event listeners and
  /// allows you to receive events through [HidDeviceEvents.onConnected]
  /// and [HidDeviceEvents.onDisconnected] streams.
  ///
  /// Example usage:
  /// ```dart
  /// // Start listening for events
  /// await Hid.startListening();
  ///
  /// // Listen for device connected events
  /// HidDeviceEvents.onConnected.listen((event) {
  ///   print('Device connected: ${event.path}');
  /// });
  ///
  /// // Listen for device disconnected events
  /// HidDeviceEvents.onDisconnected.listen((event) {
  ///   print('Device disconnected: ${event.path}');
  /// });
  /// ```
  static Future<void> startListening() async {
    await HidPlatform.instance.startListening();
    await HidDeviceEvents.startListening();
  }

  /// Stop listening for HID device events.
  ///
  /// Call this method when you no longer need to receive device
  /// connection/disconnection events.
  static Future<void> stopListening() async {
    await HidDeviceEvents.stopListening();
    await HidPlatform.instance.stopListening();
  }
}
