/// Web platform implementation for HID devices.
///
/// This implementation uses the browser's WebHID API.

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import '../hid_device.dart';
import '../hid_exception.dart';
import '../hid_platform_interface.dart';
import '../hid_device_events.dart';
import 'interop/js_interop.dart';

/// Web platform implementation of [HidPlatform].
class HidWeb extends HidPlatform {
  /// The underlying JavaScript HID interface.
  final JSHid _jsHid;

  /// Stream controller for connection events.
  StreamController<HidDeviceEvent>? _connectController;

  /// Stream controller for disconnection events.de
  StreamController<HidDeviceEvent>? _disconnectController;

  /// Cached devices.
  final Map<String, HidDeviceWeb> _devices = {};

  HidWeb._(this._jsHid);

  static HidWeb? _instance;

  /// Register this platform implementation.
  static void registerWith(Registrar registrar) {
    final hid = getNavigatorHid();
    if (hid != null) {
      _instance = HidWeb._(hid);
      HidPlatform.instance = _instance!;
    }
  }

  /// Checks if the WebHID API is available.
  static bool get isSupported => getNavigatorHid() != null;

  @override
  Future<List<HidDevice>> getDevices({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  }) async {
    try {
      final jsDevices = await _jsHid.getDevices().toDart;
      final devices = <HidDevice>[];

      for (final jsDevice in jsDevices.toDart) {
        // Apply filters
        if (vendorId != null && jsDevice.vendorId != vendorId) continue;
        if (productId != null && jsDevice.productId != productId) continue;

        final device = HidDeviceWeb._(jsDevice);
        _devices[device.id] = device;
        devices.add(device);
      }

      return devices;
    } catch (e) {
      throw HidException('Failed to get devices: $e');
    }
  }

  /// Request device access from the user.
  ///
  /// This shows a browser permission dialog.
  Future<List<HidDevice>> requestDevice({
    List<DeviceFilter>? filters,
  }) async {
    try {
      final jsFilters = filters?.map((f) => f.toJS()).toList() ?? [];
      final options = JSRequestOptions(
        filters: jsFilters.toJS,
      );

      final jsDevices = await _jsHid.requestDevice(options).toDart;
      final devices = <HidDevice>[];

      for (final jsDevice in jsDevices.toDart) {
        final device = HidDeviceWeb._(jsDevice);
        _devices[device.id] = device;
        devices.add(device);
      }

      return devices;
    } catch (e) {
      throw _parseException(e, 'requestDevice');
    }
  }

  @override
  Future<void> startListening() async {
    _startListeningToConnect();
    _startListeningToDisconnect();
  }

  @override
  Future<void> stopListening() async {
    _stopListeningToConnect();
    _stopListeningToDisconnect();
  }

  void _startListeningToConnect() {
    _connectController ??= StreamController<HidDeviceEvent>.broadcast(
      onListen: () {
        _jsHid.onconnect = ((JSAny event) {
          final e = event as JSConnectionEvent;
          final device = HidDeviceWeb._(e.device);
          _devices[device.id] = device;
          _connectController?.add(HidDeviceEvent(
            path: device.path,
            vendorId: device.vendorId,
            productId: device.productId,
          ));
        }).toJS;
      },
      onCancel: _stopListeningToConnect,
    );
  }

  void _stopListeningToConnect() {
    _jsHid.onconnect = null;
    _connectController?.close();
    _connectController = null;
  }

  void _startListeningToDisconnect() {
    _disconnectController ??= StreamController<HidDeviceEvent>.broadcast(
      onListen: () {
        _jsHid.ondisconnect = ((JSAny event) {
          final e = event as JSConnectionEvent;
          final device = HidDeviceWeb._(e.device);
          _disconnectController?.add(HidDeviceEvent(
            path: device.path,
            vendorId: device.vendorId,
            productId: device.productId,
          ));
        }).toJS;
      },
      onCancel: _stopListeningToDisconnect,
    );
  }

  void _stopListeningToDisconnect() {
    _jsHid.ondisconnect = null;
    _disconnectController?.close();
    _disconnectController = null;
  }

  Exception _parseException(dynamic error, String context) {
    final errorStr = error?.toString() ?? '';
    String? name;

    try {
      if (error is JSObject) {
        final nameVal = error['name'];
        if (nameVal != null) {
          name = (nameVal as JSString).toDart;
        }
      }
    } catch (_) {}

    final errorId = (name ?? errorStr).toLowerCase();

    if (errorId.contains('notallowed') || errorId.contains('permission')) {
      return HidException('$context: Permission denied');
    }
    if (errorId.contains('notfound')) {
      return HidException('$context: Device not found');
    }
    if (errorId.contains('notsupported')) {
      return HidException('$context: Not supported');
    }
    if (errorId.contains('invalidstate')) {
      return HidException('$context: Invalid state');
    }
    if (errorId.contains('security')) {
      return HidException('$context: Security error');
    }

    return HidException('$context: $errorStr');
  }
}

/// Web HID device implementation.
class HidDeviceWeb extends HidDevice {
  final JSDevice _jsDevice;

  StreamController<Uint8List>? _inputReportController;
  bool _isOpen = false;

  HidDeviceWeb._(this._jsDevice);

  @override
  String get id => 'web_${_jsDevice.vendorId}_${_jsDevice.productId}';

  @override
  String get path => 'web:${_jsDevice.vendorId}:${_jsDevice.productId}';

  @override
  int get vendorId => _jsDevice.vendorId;

  @override
  int get productId => _jsDevice.productId;

  @override
  String get serialNumber => '';

  @override
  int get releaseNumber => 0;

  @override
  String get manufacturer => '';

  @override
  String get productName => _jsDevice.productName;

  @override
  int get usagePage => 0;

  @override
  int get usage => 0;

  @override
  int get interfaceNumber => 0;

  @override
  int get busType => 0x03; // USB

  @override
  bool get isOpen => _isOpen;

  @override
  Future<HidReportDescriptor> getReportDescriptor() async {
    if (!_isOpen) {
      throw StateError('Device must be opened first');
    }

    final jsCollections = _jsDevice.collections.toDart;
    final collections = <HidCollection>[];
    final inputs = <HidReportItem>[];
    final outputs = <HidReportItem>[];
    final features = <HidReportItem>[];

    for (final jsCollection in jsCollections) {
      collections.add(_collectionFromJS(jsCollection, inputs, outputs, features));
    }

    return HidReportDescriptor(
      rawBytes: Uint8List(0),
      collections: collections,
      inputs: inputs,
      outputs: outputs,
      features: features,
    );
  }

  HidCollection _collectionFromJS(
    JSCollectionInfo jsCollection,
    List<HidReportItem> inputs,
    List<HidReportItem> outputs,
    List<HidReportItem> features,
  ) {
    final items = <HidReportItem>[];

    if (jsCollection.inputReports != null) {
      for (final report in jsCollection.inputReports!.toDart) {
        items.addAll(_reportsFromJS(report, HidReportType.input, inputs));
      }
    }
    if (jsCollection.outputReports != null) {
      for (final report in jsCollection.outputReports!.toDart) {
        items.addAll(_reportsFromJS(report, HidReportType.output, outputs));
      }
    }
    if (jsCollection.featureReports != null) {
      for (final report in jsCollection.featureReports!.toDart) {
        items.addAll(_reportsFromJS(report, HidReportType.feature, features));
      }
    }

    final children = jsCollection.children?.toDart
        .map((c) => _collectionFromJS(c, inputs, outputs, features))
        .toList() ?? [];

    return HidCollection(
      usagePage: jsCollection.usagePage ?? 0,
      usage: jsCollection.usage ?? 0,
      collectionType: jsCollection.type,
      children: children,
      items: items,
    );
  }

  List<HidReportItem> _reportsFromJS(
    JSReportInfo report,
    HidReportType type,
    List<HidReportItem> targetList,
  ) {
    final items = <HidReportItem>[];
    int bitPosition = 0;

    for (final jsItem in report.items.toDart) {
      final item = HidReportItem(
        reportType: type,
        reportId: report.reportId,
        usagePage: jsItem.usagePage ?? 0,
        usage: jsItem.isRange ? null : jsItem.usages?.toDart.firstOrNull?.toDartInt,
        usageMinimum: jsItem.usageMinimum,
        usageMaximum: jsItem.usageMaximum,
        logicalMinimum: jsItem.logicalMinimum,
        logicalMaximum: jsItem.logicalMaximum,
        physicalMinimum: jsItem.physicalMinimum,
        physicalMaximum: jsItem.physicalMaximum,
        reportSize: jsItem.reportSize,
        reportCount: jsItem.reportCount,
        unitExponent: jsItem.unitExponent,
        unit: null,
        isArray: jsItem.isArray,
        isAbsolute: jsItem.isAbsolute,
        hasNull: jsItem.hasNull,
        isVariable: !jsItem.isConstant,
        bitPosition: bitPosition,
      );

      bitPosition += jsItem.reportSize * jsItem.reportCount;
      items.add(item);
      targetList.add(item);
    }

    return items;
  }

  @override
  Future<void> open() async {
    if (_isOpen) {
      throw StateError('Device is already open');
    }
    try {
      await _jsDevice.open().toDart;
      _isOpen = true;
    } catch (e) {
      throw HidException('Failed to open device: $e');
    }
  }

  @override
  Future<void> close() async {
    if (!_isOpen) {
      throw StateError('Device is not open');
    }
    try {
      await _jsDevice.close().toDart;
      await _inputReportController?.close();
      _inputReportController = null;
      _isOpen = false;
    } catch (e) {
      throw HidException('Failed to close device: $e');
    }
  }

  @override
  Stream<int> inputStream() {
    if (!_isOpen) {
      throw StateError('Device must be opened first');
    }
    _inputReportController ??= StreamController<Uint8List>.broadcast(
      onListen: _startListeningToInputReports,
      onCancel: _stopListeningToInputReports,
    );
    return _inputReportController!.stream.expand((list) => list);
  }

  @override
  Future<Uint8List> receiveReport(int reportLength, {Duration? timeout}) async {
    if (!_isOpen) {
      throw StateError('Device must be opened first');
    }
    if (timeout != null) {
      return await _inputReportController!.stream.timeout(timeout).first;
    }
    return await _inputReportController!.stream.first;
  }

  @override
  Future<void> sendReport(Uint8List data, {int reportId = 0x00}) async {
    if (!_isOpen) {
      throw StateError('Device must be opened first');
    }
    try {
      await _jsDevice.sendReport(reportId, data.toJSArrayBuffer()).toDart;
    } catch (e) {
      throw HidException('Failed to send report: $e');
    }
  }

  @override
  Future<void> sendOutputReport(Uint8List data, {int reportId = 0x00}) async {
    await sendReport(data, reportId: reportId);
  }

  @override
  Future<void> sendFeatureReport(Uint8List data, {int reportId = 0x00}) async {
    if (!_isOpen) {
      throw StateError('Device must be opened first');
    }
    try {
      await _jsDevice.sendFeatureReport(reportId, data.toJSArrayBuffer()).toDart;
    } catch (e) {
      throw HidException('Failed to send feature report: $e');
    }
  }

  @override
  Future<Uint8List> receiveFeatureReport(int reportId, {int bufferSize = 1024}) async {
    if (!_isOpen) {
      throw StateError('Device must be opened first');
    }
    try {
      final jsDataView = await _jsDevice.receiveFeatureReport(reportId).toDart;
      return jsDataView.toUint8List();
    } catch (e) {
      throw HidException('Failed to receive feature report: $e');
    }
  }

  @override
  Future<String> getIndexedString(int index, {int maxLength = 256}) async {
    throw UnsupportedError('getIndexedString is not supported on Web');
  }

  void _startListeningToInputReports() {
    _jsDevice.oninputreport = ((JSAny event) {
      final e = event as JSInputReportEvent;
      final data = e.data.toUint8List();
      _inputReportController?.add(data);
    }).toJS;
  }

  void _stopListeningToInputReports() {
    _jsDevice.oninputreport = null;
  }
}

/// Device filter for WebHID.
class DeviceFilter {
  final int? vendorId;
  final int? productId;
  final int? usagePage;
  final int? usage;

  DeviceFilter({
    this.vendorId,
    this.productId,
    this.usagePage,
    this.usage,
  });

  JSDeviceFilter toJS() {
    return JSDeviceFilter(
      vendorId: vendorId,
      productId: productId,
      usagePage: usagePage,
      usage: usage,
    );
  }
}
