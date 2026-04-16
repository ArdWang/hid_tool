import 'package:flutter/services.dart';
import 'package:hid_tool/src/android/hid_device_android.dart';
import 'package:hid_tool/src/hid_device.dart';
import 'package:hid_tool/src/hid_platform_interface.dart';


class HidAndroid extends HidPlatform {
  static const MethodChannel _channel = MethodChannel('hid_tool');

  static void registerWith() {
    HidPlatform.instance = HidAndroid();
  }

  @override
  Future<List<HidDevice>> getDevices({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  }) async {
    final devices = await _channel.invokeListMethod<Map<Object?, Object?>>(
          'getDevices',
          <String, Object?>{
            'vendorId': vendorId,
            'productId': productId,
            'usagePage': usagePage,
            'usage': usage,
          },
        ) ??
        const <Map<Object?, Object?>>[];

    return devices
        .map((device) => HidDeviceAndroid.fromMap(device))
        .toList(growable: false);
  }

  @override
  Future<void> startListening() async {
    // Event stream setup is handled by HidDeviceEvents.
  }

  @override
  Future<void> stopListening() async {
    // Event stream teardown is handled by HidDeviceEvents.
  }
}
