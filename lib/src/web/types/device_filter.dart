/// HID device filter.
///
/// Holds optional filter fields used when requesting devices.

import 'dart:js_interop';
import '../interop/js_interop.dart';

class DeviceFilter {
  /// The USB vendor ID (unsigned long). Must be between 0 and 4294967295 (0xFFFFFFFF).
  final int? vendorId;

  /// The USB product ID (unsigned short). Must be between 0 and 65535 (0xFFFF).
  final int? productId;

  /// The HID usage page (unsigned short). Must be between 0 and 65535 (0xFFFF).
  final int? usagePage;

  /// The HID usage (unsigned short). Must be between 0 and 65535 (0xFFFF).
  final int? usage;

  DeviceFilter({this.vendorId, this.productId, this.usagePage, this.usage}) {
    _validateRange(vendorId, 'vendorId');
    _validateRange(productId, 'productId');
    _validateRange(usagePage, 'usagePage');
    _validateRange(usage, 'usage');
  }

  void _validateRange(int? value, String name) {
    if (value == null) {
      return;
    }
    final max = name == 'vendorId' ? 0xFFFFFFFF : 0xFFFF;
    if (value < 0 || value > max) {
      throw ArgumentError('$name must be between 0 and $max, got $value');
    }
  }

  /// Converts this filter to a JavaScript object for use with the WebHID API.
  JSDeviceFilter toJS() {
    final map = <String, Object?>{};
    if (vendorId != null) map['vendorId'] = vendorId;
    if (productId != null) map['productId'] = productId;
    if (usagePage != null) map['usagePage'] = usagePage;
    if (usage != null) map['usage'] = usage;

    return map.jsify() as JSDeviceFilter;
  }

  @override
  String toString() {
    final parts = <String>[];
    if (vendorId != null) {
      parts.add('vendorId: 0x${vendorId!.toRadixString(16)}');
    }
    if (productId != null) {
      parts.add('productId: 0x${productId!.toRadixString(16)}');
    }
    if (usagePage != null) {
      parts.add('usagePage: 0x${usagePage!.toRadixString(16)}');
    }
    if (usage != null) {
      parts.add('usage: 0x${usage!.toRadixString(16)}');
    }
    return 'DeviceFilter(${parts.join(', ')})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is DeviceFilter &&
        other.vendorId == vendorId &&
        other.productId == productId &&
        other.usagePage == usagePage &&
        other.usage == usage;
  }

  @override
  int get hashCode {
    return Object.hash(vendorId, productId, usagePage, usage);
  }
}
