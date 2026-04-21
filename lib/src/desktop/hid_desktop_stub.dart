/// Empty platform stub for non-desktop platforms.
///
/// This file provides stub implementations for desktop platform classes
/// when building for mobile/web platforms.

import 'package:hid_tool/src/hid_platform_interface.dart';
import 'package:hid_tool/src/hid_device.dart';

/// Stub implementation for Windows on non-Windows platforms.
class HidWindows extends HidPlatform {
  static void registerWith() {
    throw UnsupportedError('HidWindows is only available on Windows');
  }

  @override
  Future<List<HidDevice>> getDevices({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  }) {
    throw UnsupportedError('HidWindows is only available on Windows');
  }
}

/// Stub implementation for macOS on non-macOS platforms.
class HidMacos extends HidPlatform {
  static void registerWith() {
    throw UnsupportedError('HidMacos is only available on macOS');
  }

  @override
  Future<List<HidDevice>> getDevices({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  }) {
    throw UnsupportedError('HidMacos is only available on macOS');
  }
}

/// Stub implementation for Linux on non-Linux platforms.
class HidLinux extends HidPlatform {
  static void registerWith() {
    throw UnsupportedError('HidLinux is only available on Linux');
  }

  @override
  Future<List<HidDevice>> getDevices({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  }) {
    throw UnsupportedError('HidLinux is only available on Linux');
  }
}
