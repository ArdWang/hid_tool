# hid_tool

[![pub](https://img.shields.io/badge/pub-0.0.8-blue)](https://pub.dev/packages/hid_tool)
[![license: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)

English | [中文](README_cn.md)

---

## Table of Contents

- [Overview](#overview)
- [Acknowledgements](#acknowledgements)
- [Disclaimer](#disclaimer)
- [Supported Platforms](#supported-platforms)
- [Installation](#installation)
- [Example Application](#example-application)
- [Usage](#usage)
- [API Reference](#api-reference)
- [Device Connection/Disconnection Events](#device-connectiondisconnection-events)
- [Planned Features](#planned-features)
- [Error Handling](#error-handling)
- [Known Issues and Limitations](#known-issues-and-limitations)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

`hid_tool` is a Flutter plugin that enables communication with HID (Human Interface Device) devices from a Flutter application.

This plugin provides a comprehensive API for interacting with HID devices across multiple desktop platforms:

- **Device enumeration** - List all connected HID devices with detailed information
- **Device communication** - Send and receive input/output/feature reports
- **Report descriptor parsing** - Get and parse HID report descriptors into structured data
- **Event listening** - Real-time device connection/disconnection notifications
- **Input stream** - Stream-based API for continuous data reception

## Acknowledgements

This project is a fork/modified version of [hid4flutter](https://github.com/vinsfortunato/hid4flutter) by vinsfortunato. We have renamed it to `hid_tool` and upgraded the underlying hidapi library to version 0.15.0 with additional methods and improvements.

Original Project: [https://github.com/vinsfortunato/hid4flutter](https://github.com/vinsfortunato/hid4flutter)

## Disclaimer

**Warning:** This plugin is currently under development, and the API may be subject to change. Use it at your own risk in a production environment.

Contributions are welcome! Feel free to submit issues and pull requests to help improve this plugin.

## Supported Platforms

- ✅ Windows
- ✅ macOS
- ✅ Linux (requires manual installation of `libhidapi-hidraw0`, see [Installation](#installation))

### Implementation Details

Desktop support (Windows/macOS/Linux) is achieved by using [hidapi](https://github.com/libusb/hidapi) (version 0.15.0) and Dart FFI.

### Planned Platform Support

Support for the following platforms is planned to be added in the near future:

- **Android**: Can be supported using MethodChannel and Android HID API.
- **Web**: Experimental WebHID API can be used to support the Web platform.

## Installation

### Step 1: Add Dependency

Add the following line to your `pubspec.yaml` file:

```yaml
dependencies:
  hid_tool: ^0.0.8
```

Replace `^0.0.8` with the latest version of the plugin.

### Step 2: Install Dependencies

Run the following command to install the dependency:

```bash
flutter pub get
```

### Step 3: Import Package

Import the `hid_tool` package in your Dart code:

```dart
import 'package:hid_tool/hid_tool.dart';
```

### Platform-Specific Notes

#### Linux

On Linux, you need to install `hidapi` manually:

```bash
sudo apt-get install libhidapi-hidraw0
```

#### macOS

On macOS, the hidapi dependency is automatically managed by CocoaPods.

#### Windows

On Windows, hidapi is compiled automatically as part of the build process.

## Example Application

A complete example application is available in the [`example/`](example/) directory. The example demonstrates:

- **Device enumeration** - List all connected HID devices
- **Event listening** - Real-time device connection/disconnection events
- **Report descriptor parsing** - Fetch and display device report descriptors
- **Device details view** - View comprehensive device information

### Running the Example

```bash
cd example
flutter pub get
flutter run
```

See [example/README.md](example/README.md) for detailed documentation.

## Usage

### Initialize and Get Devices

```dart
import 'package:hid_tool/hid_tool.dart';

// Get all connected HID devices
List<HidDevice> devices = await Hid.getDevices();

// Get devices by Vendor ID and Product ID
List<HidDevice> filteredDevices = await Hid.getDevices(
  vendorId: 0x046D,
  productId: 0xC52B,
);

// Get devices by Usage Page and Usage
List<HidDevice> usageFilteredDevices = await Hid.getDevices(
  usagePage: 0xFF00,
  usage: 0x01,
);
```

### Open and Close Device

```dart
final HidDevice device = devices.first;

try {
  // Open the device connection
  await device.open();

  // Check if device is open
  if (device.isOpen) {
    print('Device is open');
  }

  // ... perform operations ...

} finally {
  // Always close the device when done
  await device.close();
}
```

### Send Output Report

```dart
final HidDevice device = ...;

try {
  await device.open();

  // Send an Output report of 32 bytes (all zeroes)
  // The reportId is optional (default is 0x00)
  // It will be prefixed to the data as per HID rules
  Uint8List data = Uint8List(32);
  await device.sendReport(data, reportId: 0x00);

} finally {
  await device.close();
}
```

### Send Output Report (Using hidapi 0.15.0+ Method)

```dart
final HidDevice device = ...;

try {
  await device.open();

  // Use the new sendOutputReport method (hidapi 0.15.0+)
  // This sends through Interrupt OUT endpoint if available
  Uint8List data = Uint8List(32);
  await device.sendOutputReport(data, reportId: 0x00);

} finally {
  await device.close();
}
```

### Receive Input Report

```dart
final HidDevice device = ...;

try {
  await device.open();

  // Receive a report of 32 bytes with timeout of 2 seconds
  Uint8List data = await device.receiveReport(32, timeout: const Duration(seconds: 2));

  // First byte is always the reportId
  int reportId = data[0];

  print('Received report with id $reportId: $data');

} finally {
  await device.close();
}
```

### Listen to Input Stream

```dart
final HidDevice device = ...;

try {
  await device.open();

  // Listen to the input stream from the device
  device.inputStream().listen((byte) {
    print('Received byte: $byte');
  });

} finally {
  await device.close();
}
```

### Send Feature Report

```dart
final HidDevice device = ...;

try {
  await device.open();

  // Send a Feature report
  Uint8List data = Uint8List(16);
  await device.sendFeatureReport(data, reportId: 0x01);

} finally {
  await device.close();
}
```

### Receive Feature Report

```dart
final HidDevice device = ...;

try {
  await device.open();

  // Receive a Feature report
  Uint8List data = await device.receiveFeatureReport(0x01, bufferSize: 64);

  print('Feature report: $data');

} finally {
  await device.close();
}
```

### Get Device Information

```dart
final HidDevice device = devices.first;

print('Path: ${device.path}');
print('Vendor ID: 0x${device.vendorId.toRadixString(16)}');
print('Product ID: 0x${device.productId.toRadixString(16)}');
print('Serial Number: ${device.serialNumber}');
print('Manufacturer: ${device.manufacturer}');
print('Product Name: ${device.productName}');
print('Usage Page: 0x${device.usagePage.toRadixString(16)}');
print('Usage: 0x${device.usage.toRadixString(16)}');
print('Interface Number: ${device.interfaceNumber}');
print('Bus Type: ${device.busType}');
```

### Get Indexed String

```dart
final HidDevice device = ...;

try {
  await device.open();

  // Get a string from the device based on its string index
  String indexedString = await device.getIndexedString(1);

  print('Indexed string: $indexedString');

} finally {
  await device.close();
}
```

### Get HID Report Descriptor

```dart
final HidDevice device = ...;

try {
  await device.open();

  // Get the HID report descriptor from the device
  // This method is available since hidapi 0.14.0+
  HidReportDescriptor descriptor = await device.getReportDescriptor();

  // Access the raw bytes
  print('Raw descriptor: ${descriptor.rawBytes}');

  // Access parsed collections
  print('Collections: ${descriptor.collections.length}');
  for (var collection in descriptor.collections) {
    print('  Collection: UsagePage=0x${collection.usagePage.toRadixString(16)}, '
          'Usage=0x${collection.usage.toRadixString(16)}, '
          'Type=${collection.collectionType}');
    print('    Items: ${collection.items.length}');
    print('    Children: ${collection.children.length}');
  }

  // Access parsed input/output/feature items
  print('Input items: ${descriptor.inputs.length}');
  print('Output items: ${descriptor.outputs.length}');
  print('Feature items: ${descriptor.features.length}');

  // Example: iterate over all input items
  for (var input in descriptor.inputs) {
    print('  Input: ReportId=${input.reportId}, '
          'UsagePage=0x${input.usagePage.toRadixString(16)}, '
          'ReportSize=${input.reportSize}, '
          'ReportCount=${input.reportCount}');
  }

} finally {
  await device.close();
}
```

## API Reference

### HidDevice Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | String | Unique device identifier |
| `path` | String | Platform-specific device path |
| `vendorId` | int | Device Vendor ID (VID) |
| `productId` | int | Device Product ID (PID) |
| `serialNumber` | String | Device serial number |
| `releaseNumber` | int | Device release number (BCD) |
| `manufacturer` | String | Manufacturer string |
| `productName` | String | Product name string |
| `usagePage` | int | Usage page for this device |
| `usage` | int | Usage for this device |
| `interfaceNumber` | int | USB interface number |
| `busType` | int | Underlying bus type (USB, Bluetooth, etc.) |
| `isOpen` | bool | Whether the device is open |

### HidDevice Methods

| Method | Description |
|--------|-------------|
| `open()` | Open the HID device connection |
| `close()` | Close the HID device connection |
| `sendReport(data, reportId)` | Send an Output report |
| `sendOutputReport(data, reportId)` | Send an Output report via Interrupt OUT (hidapi 0.15.0+) |
| `receiveReport(length, timeout)` | Receive an Input report |
| `inputStream()` | Get a stream of input bytes |
| `sendFeatureReport(data, reportId)` | Send a Feature report |
| `receiveFeatureReport(reportId, bufferSize)` | Receive a Feature report |
| `getIndexedString(index, maxLength)` | Get a string by its index |
| `getReportDescriptor()` | Get and parse the HID report descriptor (hidapi 0.14.0+) |

### Report Descriptor Classes

| Class | Description |
|-------|-------------|
| `HidReportDescriptor` | Represents a parsed HID report descriptor |
| `HidCollection` | Represents a HID collection in the descriptor |
| `HidReportItem` | Represents a report item (Input/Output/Feature) |
| `HidReportType` | Enum for report type (input/output/feature) |

### HidReportDescriptor Properties

| Property | Type | Description |
|----------|------|-------------|
| `rawBytes` | Uint8List | The raw bytes of the report descriptor |
| `collections` | List<HidCollection> | Top-level collections in the descriptor |
| `inputs` | List<HidReportItem> | All input report items |
| `outputs` | List<HidReportItem> | All output report items |
| `features` | List<HidReportItem> | All feature report items |

### HidCollection Properties

| Property | Type | Description |
|----------|------|-------------|
| `usagePage` | int | The usage page of this collection |
| `usage` | int | The usage of this collection |
| `collectionType` | int | The type of collection (Physical, Application, Logical, etc.) |
| `children` | List<HidCollection> | Child collections (nested collections) |
| `items` | List<HidReportItem> | Report items directly in this collection |
| `parent` | HidCollection? | Parent collection (null for top-level collections) |

### HidReportItem Properties

| Property | Type | Description |
|----------|------|-------------|
| `reportType` | HidReportType | The type of report item (Input, Output, Feature) |
| `reportId` | int | The report ID (0 if not used) |
| `usagePage` | int | The usage page for this item |
| `usage` | int? | The usage for this item |
| `usageMinimum` | int? | The minimum usage (for ranges) |
| `usageMaximum` | int? | The maximum usage (for ranges) |
| `logicalMinimum` | int? | The logical minimum value |
| `logicalMaximum` | int? | The logical maximum value |
| `physicalMinimum` | int? | The physical minimum value |
| `physicalMaximum` | int? | The physical maximum value |
| `reportSize` | int | The size of each report field in bits |
| `reportCount` | int | The number of report fields |
| `unitExponent` | int? | The unit exponent |
| `unit` | int? | The unit |
| `isArray` | bool | Whether the item is an array |
| `isAbsolute` | bool | Whether the item uses absolute positioning |
| `hasNull` | bool | Whether null state is supported |
| `isVariable` | bool | Whether this item has variable size |
| `bitPosition` | int | Bit position in the report |

## Device Connection/Disconnection Events

The plugin provides a stream-based API for listening to HID device connection and disconnection events without polling.

### Example Usage

```dart
import 'package:hid_tool/hid_tool.dart';

// Start listening for device events
await Hid.startListening();

// Listen for device connected events
HidDeviceEvents.onConnected.listen((event) {
  print('Device connected: ${event.path}');
  print('  Vendor ID: 0x${event.vendorId?.toRadixString(16) ?? 'unknown'}');
  print('  Product ID: 0x${event.productId?.toRadixString(16) ?? 'unknown'}');
});

// Listen for device disconnected events
HidDeviceEvents.onDisconnected.listen((event) {
  print('Device disconnected: ${event.path}');
});

// Stop listening when no longer needed
await Hid.stopListening();
```

### HidDeviceEvent Properties

| Property | Type | Description |
|----------|------|-------------|
| `path` | String | The device path identifier |
| `vendorId` | int? | The vendor ID of the device |
| `productId` | int? | The product ID of the device |
| `timestamp` | DateTime | The timestamp of the event |

## Planned Features

These features are planned for future releases:

- **Android Support**: Add Android platform support using MethodChannel and Android HID API.
- **Web Support**: Add Web platform support using WebHID API.

## Error Handling

The plugin throws `HidException` when HID operations fail:

```dart
try {
  await device.open();
  await device.sendReport(data);
} on HidException catch (e) {
  print('HID Error: ${e.message}');
} on StateError catch (e) {
  print('State Error: ${e.message}');
}
```

## Known Issues and Limitations

### Current Implementation Notes

1. **Send report response handling**: When using `sendReport()`, `sendOutputReport()`, or `sendFeatureReport()`, if the number of bytes sent differs from the expected buffer length, the current implementation does not handle this case. This is marked with TODO comments in the source code for future improvement.

2. **Input stream polling**: The `inputStream()` method uses polling with a 100-microsecond interval. This may be adjusted in future versions for better performance or power efficiency.

3. **Error handling for partial writes**: When sending reports, if a partial write occurs (result != buffer.length), the behavior is currently undefined and may be improved in future releases.

### Platform-Specific Limitations

- **Linux**: Device event listening requires proper udev permissions. Some distributions may need additional configuration.
- **macOS**: The minimum deployment target is macOS 10.13 due to Xcode compatibility requirements.
- **Windows**: HID device access may require administrator privileges for certain devices.

## Contributing

Contributions are welcome! Here's how you can help:

- **Report bugs**: Submit an issue on the [GitHub repository](https://github.com/ArdWang/hid_tool/issues) with a detailed description of the problem.
- **Suggest features**: Open an issue to discuss new feature ideas before implementation.
- **Submit pull requests**: Fork the repository, make your changes, and submit a pull request. Please ensure your code follows the existing code style and includes appropriate tests.
- **Improve documentation**: Help improve documentation by fixing typos, adding examples, or clarifying explanations.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
