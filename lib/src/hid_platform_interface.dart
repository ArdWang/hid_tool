import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:hid_tool/src/hid_device.dart';

abstract class HidPlatform extends PlatformInterface {
  HidPlatform() : super(token: _token);

  static final Object _token = Object();

  static late HidPlatform _instance;

  /// The default instance of [HidPlatform] to use.
  ///
  /// Defaults to [HidPlatform].
  static HidPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [HidPlatform] when
  /// they register themselves.
  static set instance(HidPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<List<HidDevice>> getDevices({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  });

  /// Start listening for HID device connection/disconnection events.
  Future<void> startListening() {
    throw UnimplementedError('startListening() has not been implemented.');
  }

  /// Stop listening for HID device connection/disconnection events.
  Future<void> stopListening() {
    throw UnimplementedError('stopListening() has not been implemented.');
  }
}
