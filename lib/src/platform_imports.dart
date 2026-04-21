/// Platform-specific imports for plugin registration.
///
/// This file uses conditional imports to export the correct platform
/// implementation for the dartPluginClass registration.

// DeviceFilter is pure Dart, available on all platforms
export 'device_filter.dart' show DeviceFilter;

// Web platform - uses stub on non-web platforms
export 'web/hid_web.dart' if (dart.library.io) 'web/hid_web_stub.dart' show HidWeb;

// Desktop platforms (Windows, macOS, Linux) - uses stub on mobile/web
export 'desktop/hid_desktop.dart' if (dart.library.html) 'desktop/hid_desktop_stub.dart' show HidWindows, HidMacos, HidLinux;

// Android platform - must come before web/desktop since android also has dart.library.io
// On Android: export hid_android.dart
// On non-Android platforms: export stub
export 'android/hid_android.dart' if (dart.library.html) 'android/hid_android_stub.dart' show HidAndroid;
