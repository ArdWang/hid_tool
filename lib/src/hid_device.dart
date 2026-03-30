import 'dart:typed_data';
import 'hid_exception.dart';

/// Represents an HID device. Provides properties for accessing information
/// about the device, methods for opening and closing the connection, and
/// the sending and receiving of reports.
///
/// Example usage:
/// ```dart
/// final HidDevice device = ...
///
/// await device.open();
///
/// // Send an Output report of 32 bytes (all zeroes).
/// // The reportId is optional (default is 0x00).
/// // It will be prefixed to the data as per HID rules.
/// Uint8List data = Uint8List(32);
/// await device.sendReport(reportId: 0x00, reportData);
///
/// // Close when no more needed
/// await device.close();
/// ```
abstract class HidDevice {
  /// Get the HID report descriptor from the device.
  ///
  /// Since version 0.14.0, @ref HID_API_VERSION >= HID_API_MAKE_VERSION(0, 14, 0)
  ///
  /// Returns a [HidReportDescriptor] object containing the parsed report descriptor
  /// structure, including collections, inputs, outputs, and features.
  ///
  /// Throws an [StateError] if the device is not open.
  /// Throws an [HidException] if the attempt to get the report descriptor fails.
  Future<HidReportDescriptor> getReportDescriptor();
  /// Get the HidDevice unique id.
  String get id;

  /// Get the platform-specific device path.
  String get path;

  /// Get the device vendor ID.
  int get vendorId;

  /// Get the device product ID.
  int get productId;

  /// Get the device serial number.
  String get serialNumber;

  /// Get the device release number in binary-coded decimal,
  /// also known as Device Version Number.
  int get releaseNumber;

  /// Get the manufacturer String.
  String get manufacturer;

  /// Get the product name String.
  String get productName;

  /// Get the usage page for this Device/Interface.
  int get usagePage;

  /// Get the usage for this Device/Interface.
  int get usage;

  /// The USB interface which this logical device represents.
  int get interfaceNumber;

  /// Get the underlying bus type.
  int get busType;

  /// Open a HID device.
  ///
  /// Must be closed by calling [close] when no more needed.
  ///
  /// Throws an [StateError] if the device is already open.
  /// Throws an [HidException] if the attempt to open the device fails.
  Future<void> open();

  /// Check if the HID device is open.
  bool get isOpen;

  /// Close the HID device.
  ///
  /// Must be called when an open device is no more needed.
  ///
  /// Throws an [StateError] if the device is not open.
  /// Throws an [HidException] if the attempt to close the device fails.
  Future<void> close();

  /// Get the Input report stream.
  ///
  /// Returns a stream containing each byte received from the device as
  /// part of an input stream.
  ///
  /// Throws an [StateError] if the device is not open.
  /// Throws an [HidException] if getting input reports fails.
  Stream<int> inputStream();

  /// Receive an Input report from the HID device.
  ///
  /// An optional [timeout] can be passed for setting
  /// the duration to wait before giving up.
  ///
  /// Throws an [StateError] if the device is not open.
  /// Throws an [TimeoutException] if the attempt to receive the report time out.
  /// Throws an [HidException] if the attempt to receive the report fails.
  Future<Uint8List> receiveReport(int reportLength, {Duration? timeout});

  /// Send an Output report to the HID device.
  ///
  /// The [reportId] will be prefixed to the HID packet as per HID rules.
  ///
  /// Throws an [StateError] if the device is not open.
  /// Throws an [HidException] if the attempt to send the report fails.
  Future<void> sendReport(Uint8List data, {int reportId = 0x00});

  /// Get a feature report from the HID device.
  ///
  /// Throws an [StateError] if the device is not open.
  /// Throws an [HidException] if the attempt to get the report fails.
  Future<Uint8List> receiveFeatureReport(
    int reportId, {
    int bufferSize = 1024,
  });

  /// Send a Feature report to the HID device.
  ///
  /// The [reportId] will be prefixed to the HID packet as per HID rules.
  ///
  /// Throws an [StateError] if the device is not open.
  /// Throws an [HidException] if the attempt to send the report fails.
  Future<void> sendFeatureReport(Uint8List data, {int reportId = 0x00});

  /// Send an Output report to the HID device using hid_send_output_report.
  ///
  /// Since version 0.15.0, @ref HID_API_VERSION >= HID_API_MAKE_VERSION(0, 15, 0)
  ///
  /// This function is similar to [sendReport], but it explicitly sends
  /// the report through the Interrupt OUT endpoint if available, which
  /// is the recommended way for sending Output reports on most platforms.
  ///
  /// The [reportId] will be prefixed to the HID packet as per HID rules.
  ///
  /// Throws an [StateError] if the device is not open.
  /// Throws an [HidException] if the attempt to send the report fails.
  Future<void> sendOutputReport(Uint8List data, {int reportId = 0x00});

  /// Get a string from an HID device, based on its string index.
  ///
  /// Throws an [StateError] if the device is not open.
  /// Throws an [HidException] if the attempt to get the string fails.
  Future<String> getIndexedString(int index, {int maxLength = 256});

  @override
  bool operator ==(covariant HidDevice other) {
    if (identical(this, other)) return true;

    return other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }

  @override
  String toString() {
    return '''
      HidDevice [
        id=$path,
        path=$path,
        vendorId=0x${vendorId.toRadixString(16)},
        productId=0x${productId.toRadixString(16)},
        serialNumber=$serialNumber,
        releaseNumber=0x${releaseNumber.toRadixString(16)},
        manufacturer=$manufacturer,
        productName=$productName,
        usagePage=0x${usagePage.toRadixString(16)},
        usage=0x${usage.toRadixString(16)},
        interfaceNumber=$interfaceNumber
      ]''';
  }
}

/// Represents a parsed HID report descriptor.
///
/// Contains the hierarchical structure of collections and report items
/// extracted from the raw HID report descriptor bytes.
class HidReportDescriptor {
  /// The raw bytes of the report descriptor
  final Uint8List rawBytes;

  /// Top-level collections in the report descriptor
  final List<HidCollection> collections;

  /// All input report items
  final List<HidReportItem> inputs;

  /// All output report items
  final List<HidReportItem> outputs;

  /// All feature report items
  final List<HidReportItem> features;

  HidReportDescriptor({
    required this.rawBytes,
    required this.collections,
    required this.inputs,
    required this.outputs,
    required this.features,
  });

  @override
  String toString() {
    return 'HidReportDescriptor(collections: ${collections.length}, '
        'inputs: ${inputs.length}, outputs: ${outputs.length}, '
        'features: ${features.length})';
  }
}

/// Represents a HID collection in the report descriptor.
///
/// Collections group related controls together, such as a keyboard,
/// mouse, or joystick.
class HidCollection {
  /// The usage page of this collection
  final int usagePage;

  /// The usage of this collection
  final int usage;

  /// The type of collection (Physical, Application, Logical, etc.)
  final int collectionType;

  /// Child collections (nested collections)
  final List<HidCollection> children;

  /// Report items directly in this collection
  final List<HidReportItem> items;

  /// Parent collection (null for top-level collections)
  final HidCollection? parent;

  HidCollection({
    required this.usagePage,
    required this.usage,
    required this.collectionType,
    required this.children,
    required this.items,
    this.parent,
  });

  @override
  String toString() {
    return 'HidCollection(usagePage: 0x${usagePage.toRadixString(16)}, '
        'usage: 0x${usage.toRadixString(16)}, '
        'type: $collectionType, children: ${children.length}, '
        'items: ${items.length})';
  }
}

/// Represents a single report item (Input, Output, or Feature).
class HidReportItem {
  /// The type of report item (Input, Output, Feature)
  final HidReportType reportType;

  /// The report ID (0 if not used)
  final int reportId;

  /// The usage page for this item
  final int usagePage;

  /// The usage for this item
  final int? usage;

  /// The minimum usage (for ranges)
  final int? usageMinimum;

  /// The maximum usage (for ranges)
  final int? usageMaximum;

  /// The logical minimum value
  final int? logicalMinimum;

  /// The logical maximum value
  final int? logicalMaximum;

  /// The physical minimum value
  final int? physicalMinimum;

  /// The physical maximum value
  final int? physicalMaximum;

  /// The size of each report field in bits
  final int reportSize;

  /// The number of report fields
  final int reportCount;

  /// The unit exponent
  final int? unitExponent;

  /// The unit
  final int? unit;

  /// Designator index
  final int? designatorIndex;

  /// String index
  final int? stringIndex;

  /// Whether the item is an array
  final bool isArray;

  /// Whether the item uses absolute positioning
  final bool isAbsolute;

  /// Whether null state is supported
  final bool hasNull;

  /// Whether this item has variable size
  final bool isVariable;

  /// Bit position in the report
  final int bitPosition;

  HidReportItem({
    required this.reportType,
    required this.reportId,
    required this.usagePage,
    this.usage,
    this.usageMinimum,
    this.usageMaximum,
    this.logicalMinimum,
    this.logicalMaximum,
    this.physicalMinimum,
    this.physicalMaximum,
    required this.reportSize,
    required this.reportCount,
    this.unitExponent,
    this.unit,
    this.designatorIndex,
    this.stringIndex,
    required this.isArray,
    required this.isAbsolute,
    required this.hasNull,
    required this.isVariable,
    required this.bitPosition,
  });

  @override
  String toString() {
    return 'HidReportItem(type: $reportType, reportId: $reportId, '
        'usagePage: 0x${usagePage.toRadixString(16)}, '
        'reportSize: $reportSize, reportCount: $reportCount)';
  }
}

/// Type of HID report
enum HidReportType {
  /// Input report - data sent from device to host
  input,

  /// Output report - data sent from host to device
  output,

  /// Feature report - configuration data exchanged via control transfers
  feature,
}
