# Changelog

All notable changes to this project will be documented in this file.

## Acknowledgements

This project is a fork/modified version of [hid4flutter](https://github.com/vinsfortunato/hid4flutter) by vinsfortunato.

---

## [0.1.1] - 2026-06-16

### Fixed

- **Device event listening UI freeze**: Fixed severe UI lag when USB cable is loose, causing rapid device connect/disconnect events to flood the event pipeline. Added three-layer debounce (native C++, Dart plugin, example app) with 300ms window to prevent duplicate events from overwhelming the platform thread.
  - Windows native layer: Device notifications are now registered only after `startListening()` is called, `IsHidDevice()` tightened to match only canonical `HID#`/`HID\` paths, and `ShouldForwardEvent()` suppresses duplicate events within 300ms.
  - Dart plugin layer: Added defensive debounce in `HidDeviceEvents` MethodCallHandler to catch any duplicates that slip through the native layer.
  - Example app: Replaced per-event `_loadConnectedDevices()` (heavy `hid_enumerate` FFI call) with debounced `_scheduleDeviceRefresh()`.
- **wchar_t encoding on macOS/Linux**: Fixed device names (manufacturer, product name, serial number) only showing the first character on non-Windows platforms. The root cause was that `wchar_t` is 4 bytes (UTF-32) on macOS/Linux/Android but was being read as UTF-16, causing the first null byte (0x0000) to be treated as a string terminator. Now correctly reads `wchar_t*` as UTF-32LE on non-Windows platforms.
- **HidException toString()**: Added `toString()` override to `HidException` so error messages are properly displayed instead of showing `Instance of 'HidException'`.
- **Example app - initState native call**: Fixed `setState() or markNeedsBuild() called during build` assertion errors in the example app. Calling `Hid.getDevices()` in `initState()` triggers native FFI calls that dispatch platform messages during the build phase. Both `DeviceListScreenState` and `_DeviceDetailDialogState` now defer native calls until after the first frame using `WidgetsBinding.instance.addPostFrameCallback`.
- **macOS sandbox entitlement**: Added `com.apple.security.device.usb` entitlement to the example app's `DebugProfile.entitlements` and `Release.entitlements`. Without this, macOS App Sandbox blocks HID device access, causing `hid_get_report_descriptor` and other operations to fail.

### Changed

- Updated `README.md` and `README_cn.md` with macOS App Sandbox USB entitlement documentation.
- Updated Known Issues sections in both READMEs to reflect current state.

---

## [0.1.0] - 2026-06-11

### Added

- Added Android HID support using MethodChannel and Android USB HID APIs

### Changed

- Updated package version to `0.1.0`
- Enhanced `Hid` class with platform registration logic
- Updated `README.md` and `README_cn.md` with updated platform documentation and version examples for `0.1.0`

### Fixed

- Removed legacy Android source package directories under `com/github/vinsfortunato/hid_tool`

---

## [0.0.8] - 2026-04-03

### Changed

- Separated documentation into English (README.md, CHANGELOG.md) and Chinese (README_cn.md, CHANGELOG_cn.md) files
- Added Contribution section to README.md
- Updated version numbers in documentation to 0.0.8

### Improved

- **extensions.dart**: Replaced custom pointer-to-string conversion with `ffi` package's built-in `Utf8` and `Utf16` methods for better efficiency
- **hid_report_descriptor_parser.dart**: Removed duplicate code in size type handling (simplified from 8 lines to 1 line)
- **hid_device_desktop.dart**: 
  - Changed TODO comments to descriptive notes about expected behavior for partial writes
  - Increased input stream polling interval from 100 microseconds to 1 millisecond for better power efficiency
  - Removed unnecessary variable initialization in `inputStream()` method

---

## [0.0.7] - 2026-03-30

### Fixed

- Fixed macOS build error "cannot find 'kIOHIDDevicePathKey' in scope" by defining the constant manually
- Added `kIOHIDDevicePathKey` constant declaration in Swift file since IOKit submodules cannot be imported directly

---

## [0.0.6] - 2026-03-30

### Fixed

- Fixed macOS build error "no such module 'IOKit.hid.IOHIDLib'" by removing invalid import statements
- Added `IOKit` framework to macOS podspec for proper linking
- Updated macOS minimum deployment target to 10.13 (Xcode compatible version)
- Fixed Windows compilation errors:
  - GUID redefinition error in `hid_tool_plugin.cpp`
  - MethodChannel `InvokeMethod` type mismatch for device events
- Added `.claude/` to `.gitignore` to prevent Claude Code settings from being committed

### Changed

- Updated all platform implementations to ensure consistent build experience

---

## [0.0.5] - 2026-03-30

### Added

- Added `.gitignore` entry for `.claude/` directory

### Changed

- Improved macOS device event listening implementation
- Updated device event listening to start only when explicitly called

---

## [0.0.4] - 2026-03-30

### Added

- Added `getReportDescriptor()` method to get and parse the HID report descriptor from the device (requires hidapi 0.14.0+)
- Added `HidReportDescriptor` class to represent parsed report descriptor with collections and report items
- Added `HidCollection` class to represent HID collections with nested structure support
- Added `HidReportItem` class to represent input/output/feature report items with full descriptor information
- Added `HidReportType` enum for report type identification
- Added `HidReportDescriptorParser` class to parse raw descriptor bytes into structured objects
- Added `HidDeviceEvents` class for listening to device connection/disconnection events on Windows, macOS, and Linux
- Added `HidDeviceEvent` class to represent a device connection/disconnection event with path, vendor ID, and product ID
- Added `Hid.startListening()` and `Hid.stopListening()` methods for managing device event listeners
- Implemented Windows platform device notification using `RegisterDeviceNotification` API
- Implemented macOS platform device notification using IOKit framework
- Implemented Linux platform device notification using udev/netlink

### Changed

- Updated README.md with documentation and examples for the new report descriptor API
- Updated README.md with documentation and examples for device event listening API

---

## [0.0.3] - 2026-03-27

- Fixed CMake configuration to properly link hidapi on MacOS

## [0.0.2] - 2026-03-27

- Fixed CMake configuration to properly link hidapi on Windows

## [0.0.1] - 2026-03-26

### Added

- Added `sendOutputReport` method using hidapi 0.15.0's new `hid_send_output_report()` function
- Added `hid_read_error()` function binding for better error handling
- Initial release of `hid_tool` (renamed from `hid4flutter`)

### Changed

- Upgraded hidapi to version 0.15.0
- Renamed package from `hid4flutter` to `hid_tool`
- Updated all platform implementations to use new naming convention
- Updated CMake configuration to use modern version syntax

---

## [0.1.3] - 2026-03-26 (Unreleased)

### Added

- Added `sendOutputReport` method using hidapi 0.15.0's new `hid_send_output_report()` function
- Added `hid_read_error()` function binding for better error handling

### Changed

- Upgraded hidapi to version 0.15.0
- Renamed package from `hid4flutter` to `hid_tool`

---

## [0.1.2] - 2026-03-26

### Fixed

- Remove CMake warning when building on Windows

### Changed

- Use git submodule to download hidapi sources on Windows
- Improve code quality

---

## [0.1.1]

### Fixed

- Fix macOS podspec summary and description
- Fix test to clear pub publish warnings

---

## [0.1.0]

### Added

- Support for macOS platform
- Support for Linux platform
- Add filters to `Hid.getDevices(...)` method
- Add a working flutter example application in /example/
- Add `inputStream()` method to `HidDevice` to get a stream of bytes received from the device as part of an input report

### Changed

- Upgrade used hidapi version to `0.14.0`
- Remove `Hid.init()` and `Hid.exit()` methods. Resources are now freed automatically when all devices get closed
- Change property `product` to `productName` in `HidDevice` class
- Improve API naming and usage
- Improve documentation
- Remove android from apparently supported platforms in pubspec since it is still not supported

### Fixed

- Compile hidapi on windows instead of bundling pre-compiled dylibs
- Remove unused/unnecessary native code
- Fix pointer of Char/WChar to String conversions
- Fix input report receiving implementation on desktop platforms

---

## [0.0.1]

### Added

- Initial release

**Note:** As of now, `hid4flutter` is only supported on Windows. Support for other platforms will be added in future releases.
