# hid_tool_example

Demonstrates how to use the hid_tool plugin with device event listening and report descriptor parsing.

## Features Demonstrated

This example application showcases the following features of the hid_tool plugin:

### 1. Device Enumeration
- List all connected HID devices
- Display device information (VID, PID, serial number, manufacturer, etc.)

### 2. Device Connection/Disconnection Events
- Real-time event listening for device plug/unplug
- Event log display with timestamps
- Automatic device list refresh on connect/disconnect

### 3. HID Report Descriptor
- Fetch and parse HID report descriptors from devices
- Display descriptor structure (collections, inputs, outputs, features)
- View raw descriptor bytes in hex format

## Running the Example

### Prerequisites

1. Make sure you have Flutter installed and configured
2. A desktop environment (Windows, macOS, or Linux)
3. At least one HID device connected (mouse, keyboard, gamepad, etc.)

### Running

```bash
# Navigate to the example directory
cd example

# Get dependencies
flutter pub get

# Run the application
flutter run
```

### Platform-Specific Setup

#### Linux

Install the required libudev development files:

```bash
sudo apt-get install libudev-dev libhidapi-hidraw0
```

#### Windows

No additional setup required. hidapi is compiled as part of the build process.

#### macOS

No additional setup required. The hidapi dependency is managed by CocoaPods.

## Usage Guide

### Viewing Connected Devices

1. Launch the application
2. The main screen displays all currently connected HID devices
3. Pull the refresh button or click the refresh icon to update the device list

### Event Listening

1. Click the **Play** button (▶) in the app bar to start listening for device events
2. The event log (top section) will show real-time connection/disconnection events
3. Connect or disconnect a HID device to see events in real-time
4. Click the **Stop** button (⏹) to stop listening

### Viewing Device Details

1. Click on any device in the list
2. The device detail dialog shows:
   - **Device Information**: Path, VID, PID, serial number, manufacturer, etc.
   - **Report Descriptor**: Raw descriptor bytes and parsed structure

### Event Log

The event log displays:
- Timestamp of each event
- Device connection events with VID/PID
- Device disconnection events
- Application status messages

You can clear the log by clicking the sweep icon.

## Code Highlights

### Starting Event Listening

```dart
import 'package:hid_tool/hid_tool.dart';

// Start listening for device events
await Hid.startListening();

// Listen for device connected events
HidDeviceEvents.onConnected.listen((event) {
  print('Device connected: ${event.path}');
  print('  VID: 0x${event.vendorId?.toRadixString(16)}');
  print('  PID: 0x${event.productId?.toRadixString(16)}');
});

// Listen for device disconnected events
HidDeviceEvents.onDisconnected.listen((event) {
  print('Device disconnected: ${event.path}');
});
```

### Getting Report Descriptor

```dart
import 'package:hid_tool/hid_tool.dart';

final device = devices.first;
await device.open();

// Get the report descriptor
final descriptor = await device.getReportDescriptor();

// Access parsed information
print('Collections: ${descriptor.collections.length}');
print('Input items: ${descriptor.inputs.length}');
print('Output items: ${descriptor.outputs.length}');
print('Feature items: ${descriptor.features.length}');

// Access raw bytes
print('Raw bytes: ${descriptor.rawBytes}');

await device.close();
```

## Screenshots

The application UI consists of:

1. **Event Log Section** (top): Displays real-time device events with timestamps
2. **Device List Section** (bottom): Shows all connected HID devices
3. **Device Detail Dialog**: Shows detailed device information and report descriptor

## Troubleshooting

### No Devices Found

- Make sure you have HID devices connected
- On Linux, check that you have permission to access HID devices
- Try running with elevated privileges if needed

### Event Listening Not Working

- Ensure you call `Hid.startListening()` before expecting events
- Check the console for any error messages
- On Linux, ensure udev is running properly

### Report Descriptor Loading Fails

- Not all HID devices expose their report descriptors
- Some devices may require special drivers
- Check the error message for details

## License

This example project is licensed under the same MIT License as the main hid_tool plugin.
