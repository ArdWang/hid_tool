/// JS interop bindings for the WebHID API.
///
/// Small, direct mappings of the browser WebHID interfaces used by the package.

import 'dart:js_interop';
import 'dart:typed_data';

/// JavaScript HID interface (navigator.hid).
///
/// Provides methods for requesting HID devices and retrieving previously authorized devices.
/// See: https://wicg.github.io/webhid/#dom-hid
@JS('HID')
extension type JSHid._(JSObject _) implements JSObject {
  /// Requests access to HID devices matching the provided filters.
  ///
  /// Shows a permission prompt to the user with devices matching the filters.
  /// Returns a promise that resolves with an array of granted devices.
  external JSPromise<JSArray<JSDevice>> requestDevice(JSRequestOptions options);

  /// Returns a promise that resolves with an array of HID devices
  /// the origin has been granted access to.
  external JSPromise<JSArray<JSDevice>> getDevices();

  /// Event handler for when a device is connected.
  external set onconnect(JSFunction? handler);
  external JSFunction? get onconnect;

  /// Event handler for when a device is disconnected.
  external set ondisconnect(JSFunction? handler);
  external JSFunction? get ondisconnect;

  /// Adds an event listener for the specified event type.
  external void addEventListener(
    String type,
    JSFunction listener, [
    JSAny options,
  ]);

  /// Removes an event listener for the specified event type.
  external void removeEventListener(
    String type,
    JSFunction listener, [
    JSAny options,
  ]);
}

/// JavaScript Device interface.
///
/// Represents a connected HID device and provides methods for communication.
/// See: https://wicg.github.io/webhid/#device-usage
@JS('Device')
extension type JSDevice._(JSObject _) implements JSObject {
  /// Whether the device is currently open for communication.
  external bool get opened;

  /// The vendor ID of the device.
  external int get vendorId;

  /// The product ID of the device.
  external int get productId;

  /// The product name string.
  external String get productName;

  /// An array of collections supported by this device.
  external JSArray<JSCollectionInfo> get collections;

  /// Opens the device for communication.
  ///
  /// Returns a promise that resolves when the device is successfully opened.
  external JSPromise<JSAny?> open();

  /// Closes the device.
  ///
  /// Returns a promise that resolves when the device is successfully closed.
  external JSPromise<JSAny?> close();

  /// Forgets the device, revoking permission.
  ///
  /// Returns a promise that resolves when the device is forgotten.
  external JSPromise<JSAny?> forget();

  /// Sends an output report to the device.
  ///
  /// [reportId] The report ID, or 0 if the device does not use report IDs.
  /// [data] The report data as a BufferSource.
  external JSPromise<JSAny?> sendReport(int reportId, JSArrayBuffer data);

  /// Sends a feature report to the device.
  ///
  /// [reportId] The report ID, or 0 if the device does not use report IDs.
  /// [data] The report data as a BufferSource.
  external JSPromise<JSAny?> sendFeatureReport(
    int reportId,
    JSArrayBuffer data,
  );

  /// Receives a feature report from the device.
  ///
  /// [reportId] The report ID, or 0 if the device does not use report IDs.
  /// Returns a promise that resolves with the report data.
  external JSPromise<JSDataView> receiveFeatureReport(int reportId);

  /// Event handler for input reports.
  external set oninputreport(JSFunction? handler);
  external JSFunction? get oninputreport;

  /// Adds an event listener for the specified event type.
  external void addEventListener(
    String type,
    JSFunction listener, [
    JSAny options,
  ]);

  /// Removes an event listener for the specified event type.
  external void removeEventListener(
    String type,
    JSFunction listener, [
    JSAny options,
  ]);
}

/// JavaScript ConnectionEvent interface.
///
/// Fired when a HID device is connected or disconnected.
/// See: https://wicg.github.io/webhid/#dom-ConnectionEvent
@JS('ConnectionEvent')
extension type JSConnectionEvent._(JSObject _) implements JSObject {
  /// The device that was connected or disconnected.
  external JSDevice get device;

  /// The event type (e.g., 'connect' or 'disconnect').
  external String get type;
}

/// JavaScript InputReportEvent interface.
///
/// Fired when an input report is received from a HID device.
/// See: https://wicg.github.io/webhid/#dom-InputReportEvent
@JS('InputReportEvent')
extension type JSInputReportEvent._(JSObject _) implements JSObject {
  /// The device that sent the report.
  external JSDevice get device;

  /// The report ID, or 0 if the device does not use report IDs.
  external int get reportId;

  /// The report data.
  external JSDataView get data;
}

/// JavaScript RequestOptions.
///
/// Options for requesting HID devices.
/// See: https://wicg.github.io/webhid/#dom-RequestOptions
extension type JSRequestOptions._(JSObject _) implements JSObject {
  external factory JSRequestOptions({
    JSArray<JSDeviceFilter>? filters,
    JSArray<JSDeviceFilter>? exclusionFilters,
  });

  external JSArray<JSDeviceFilter>? get filters;
  external JSArray<JSDeviceFilter>? get exclusionFilters;
}

/// JavaScript DeviceFilter.
///
/// Filter criteria for HID device requests.
/// See: https://wicg.github.io/webhid/#dom-DeviceFilter
extension type JSDeviceFilter._(JSObject _) implements JSObject {
  external factory JSDeviceFilter({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  });

  external int? get vendorId;
  external int? get productId;
  external int? get usagePage;
  external int? get usage;
}

/// JavaScript CollectionInfo.
///
/// Information about a HID collection within a device.
/// See: https://wicg.github.io/webhid/#dom-CollectionInfo
extension type JSCollectionInfo._(JSObject _) implements JSObject {
  /// The usage page of the collection.
  external int? get usagePage;

  /// The usage of the collection.
  external int? get usage;

  /// The collection type.
  external int get type;

  /// Child collections.
  external JSArray<JSCollectionInfo>? get children;

  /// Input reports in this collection.
  external JSArray<JSReportInfo>? get inputReports;

  /// Output reports in this collection.
  external JSArray<JSReportInfo>? get outputReports;

  /// Feature reports in this collection.
  external JSArray<JSReportInfo>? get featureReports;
}

/// JavaScript ReportInfo.
///
/// Information about a HID report.
/// See: https://wicg.github.io/webhid/#dom-ReportInfo
extension type JSReportInfo._(JSObject _) implements JSObject {
  /// The report ID, or 0 if the device does not use report IDs.
  external int get reportId;

  /// The items in this report.
  external JSArray<JSReportItem> get items;
}

/// JavaScript ReportItem.
///
/// Information about an item in a HID report.
/// See: https://wicg.github.io/webhid/#dom-ReportItem
extension type JSReportItem._(JSObject _) implements JSObject {
  /// Whether the item is an array.
  external bool get isArray;

  /// Whether the item is a constant value.
  external bool get isConstant;

  /// Whether the item represents a volatile value.
  external bool get isVolatile;

  /// Whether the item uses a usage range (usageMinimum/usageMaximum).
  external bool get isRange;

  /// Whether the item has a null state.
  external bool get hasNull;

  /// Whether the item is buffered bytes.
  external bool get isBufferedBytes;

  /// Whether the item is absolute.
  external bool get isAbsolute;

  /// The usage page of the report item.
  external int? get usagePage;

  /// Whether the item wraps around.
  external bool get wrap;

  /// Whether the item is linear.
  external bool get isLinear;

  /// Whether the item has a preferred state.
  external bool get hasPreferredState;

  /// Usages associated with the item.
  external JSArray<JSNumber>? get usages;

  /// Minimum usage for the item.
  external int? get usageMinimum;

  /// Maximum usage for the item.
  external int? get usageMaximum;

  /// Report size in bits.
  external int get reportSize;

  /// Report count.
  external int get reportCount;

  /// Unit exponent.
  external int? get unitExponent;

  /// Unit system.
  external String? get unitSystem;

  /// Unit factor for length.
  external int? get unitFactorLengthExponent;

  /// Unit factor for mass.
  external int? get unitFactorMassExponent;

  /// Unit factor for time.
  external int? get unitFactorTimeExponent;

  /// Unit factor for temperature.
  external int? get unitFactorTemperatureExponent;

  /// Unit factor for current.
  external int? get unitFactorCurrentExponent;

  /// Unit factor for luminous intensity.
  external int? get unitFactorLuminousIntensityExponent;

  /// Logical minimum value.
  external int get logicalMinimum;

  /// Logical maximum value.
  external int get logicalMaximum;

  /// Physical minimum value.
  external int? get physicalMinimum;

  /// Physical maximum value.
  external int? get physicalMaximum;

  /// String descriptors.
  external JSArray<JSString>? get strings;
}

/// Extension to access the HID interface from the Navigator.
@JS()
external JSHid get hid;

/// Helper extension for JSDataView to access buffer properties.
extension JSDataViewExt on JSDataView {
  /// Gets the buffer from the DataView.
  external JSArrayBuffer get buffer;

  /// Gets the byte offset.
  external JSNumber get byteOffset;

  /// Gets the byte length.
  external JSNumber get byteLength;

  /// Gets an unsigned 8-bit integer at the specified offset.
  external JSNumber getUint8(JSNumber byteOffset);

  /// Efficiently converts JSDataView to Uint8List using the underlying buffer.
  Uint8List toUint8List() {
    final offset = byteOffset.toDartInt;
    final length = byteLength.toDartInt;
    final uint8List = buffer.toDart.asUint8List();
    // Return a view of the specific range
    return Uint8List.view(uint8List.buffer, offset, length);
  }
}

/// Extension for Navigator to access HID.
@JS('navigator')
external JSObject get _navigator;

/// Extension for JSObject to get properties.
extension JSObjectProperties on JSObject {
  external JSAny? operator [](String property);
}

/// Gets the HID interface from the navigator.
JSHid? getNavigatorHid() {
  try {
    return _navigator['hid'] as JSHid?;
  } catch (e) {
    return null;
  }
}

/// JavaScript DOMException interface.
///
/// Represents an error that occurs in the DOM.
/// See: https://developer.mozilla.org/en-US/docs/Web/API/DOMException
@JS('DOMException')
extension type JSDOMException._(JSObject _) implements JSObject {
  /// The name of the exception (e.g., 'NotAllowedError', 'NotFoundError').
  external String? get name;

  /// The message describing the exception.
  external String? get message;
}

/// Utility functions for converting between Dart and JavaScript types.
extension JSArrayBufferExt on JSArrayBuffer {
  /// Converts a JavaScript ArrayBuffer to a Dart Uint8List.
  Uint8List toUint8List() {
    return toDart.asUint8List();
  }
}

/// Extension to convert Dart typed data to JavaScript ArrayBuffer.
extension Uint8ListToJSArrayBuffer on Uint8List {
  /// Converts a Dart Uint8List to a JavaScript ArrayBuffer.
  JSArrayBuffer toJSArrayBuffer() {
    // Convert Uint8List to JSUint8Array first, then get its buffer
    final jsUint8Array = toJS;
    return jsUint8Array.toDart.buffer.toJS;
  }
}
