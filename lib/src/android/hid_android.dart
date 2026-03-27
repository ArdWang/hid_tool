import 'package:hid_tool/src/hid_device.dart';
import 'package:hid_tool/src/hid_platform_interface.dart';

class HidAndroid extends HidPlatform {
  static void registerWith() {
    HidPlatform.instance = HidAndroid();
  }

  @override
  Future<List<HidDevice>> getDevices({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  }) {
    // TODO: implement getDevices
    throw UnimplementedError();
  }
}
