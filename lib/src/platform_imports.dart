/// Platform-specific imports for plugin registration.
///
/// This file exports the platform implementations used by the
/// dartPluginClass registration.

// DeviceFilter is pure Dart, available on all platforms
export 'device_filter.dart' show DeviceFilter;

// Desktop platforms (Windows, macOS, Linux)
export 'desktop/hid_desktop.dart' show HidWindows, HidMacos, HidLinux;

// Android platform
export 'android/hid_android.dart' show HidAndroid;
