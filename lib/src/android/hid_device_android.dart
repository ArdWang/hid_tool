import 'dart:async';

import 'package:flutter/services.dart';
import 'package:hid_tool/src/desktop/hid_report_descriptor_parser.dart';
import 'package:hid_tool/src/hid_device.dart';
import 'package:hid_tool/src/hid_exception.dart';

class HidDeviceAndroid extends HidDevice {
  HidDeviceAndroid({
    required String id,
    required String path,
    required int vendorId,
    required int productId,
    required String serialNumber,
    required int releaseNumber,
    required String manufacturer,
    required String productName,
    required int usagePage,
    required int usage,
    required int interfaceNumber,
    required int busType,
    required int inputReportSize,
  })  : _id = id,
        _path = path,
        _vendorId = vendorId,
        _productId = productId,
        _serialNumber = serialNumber,
        _releaseNumber = releaseNumber,
        _manufacturer = manufacturer,
        _productName = productName,
        _usagePage = usagePage,
        _usage = usage,
        _interfaceNumber = interfaceNumber,
        _busType = busType,
        _inputReportSize = inputReportSize;

  static const MethodChannel _channel = MethodChannel('hid_tool');

  final String _id;
  final String _path;
  final int _vendorId;
  final int _productId;
  final String _serialNumber;
  final int _releaseNumber;
  final String _manufacturer;
  final String _productName;
  final int _usagePage;
  final int _usage;
  final int _interfaceNumber;
  final int _busType;
  final int _inputReportSize;

  bool _isOpen = false;

  factory HidDeviceAndroid.fromMap(Map<Object?, Object?> map) {
    int readInt(String key, [int fallback = 0]) {
      final value = map[key];
      return value is int ? value : fallback;
    }

    String readString(String key) {
      final value = map[key];
      return value is String ? value : '';
    }

    final path = readString('path');
    return HidDeviceAndroid(
      id: readString('id').isNotEmpty ? readString('id') : path,
      path: path,
      vendorId: readInt('vendorId'),
      productId: readInt('productId'),
      serialNumber: readString('serialNumber'),
      releaseNumber: readInt('releaseNumber'),
      manufacturer: readString('manufacturer'),
      productName: readString('productName'),
      usagePage: readInt('usagePage'),
      usage: readInt('usage'),
      interfaceNumber: readInt('interfaceNumber'),
      busType: readInt('busType', 1),
      inputReportSize: readInt('inputReportSize', 64),
    );
  }

  @override
  String get id => _id;

  @override
  String get path => _path;

  @override
  int get vendorId => _vendorId;

  @override
  int get productId => _productId;

  @override
  String get serialNumber => _serialNumber;

  @override
  int get releaseNumber => _releaseNumber;

  @override
  String get manufacturer => _manufacturer;

  @override
  String get productName => _productName;

  @override
  int get usagePage => _usagePage;

  @override
  int get usage => _usage;

  @override
  int get interfaceNumber => _interfaceNumber;

  @override
  int get busType => _busType;

  @override
  bool get isOpen => _isOpen;

  @override
  Future<void> open() async {
    if (isOpen) {
      throw StateError('Device is already open.');
    }

    await _invokeVoid('openDevice');
    _isOpen = true;
  }

  @override
  Future<void> close() async {
    if (!isOpen) {
      throw StateError('Device is not open.');
    }

    try {
      await _invokeVoid('closeDevice');
    } finally {
      _isOpen = false;
    }
  }

  @override
  Stream<int> inputStream() async* {
    if (!isOpen) {
      throw StateError('Device is not open.');
    }

    final reportLength = _inputReportSize > 0 ? _inputReportSize : 64;
    while (isOpen) {
      Uint8List report;
      try {
        report = await receiveReport(
          reportLength,
          timeout: const Duration(milliseconds: 250),
        );
      } on TimeoutException {
        continue;
      }

      for (final byte in report) {
        yield byte;
      }
    }
  }

  @override
  Future<Uint8List> receiveReport(
    int reportLength, {
    Duration? timeout,
  }) async {
    _ensureOpen();

    return _invokeBytes(
      'receiveReport',
      <String, Object?>{
        'reportLength': reportLength,
        'timeout': timeout?.inMilliseconds,
      },
    );
  }

  @override
  Future<void> sendReport(Uint8List data, {int reportId = 0x00}) async {
    _ensureOpen();
    await _invokeVoid(
      'sendReport',
      <String, Object?>{
        'data': data,
        'reportId': reportId,
      },
    );
  }

  @override
  Future<Uint8List> receiveFeatureReport(
    int reportId, {
    int bufferSize = 1024,
  }) async {
    _ensureOpen();

    return _invokeBytes(
      'receiveFeatureReport',
      <String, Object?>{
        'reportId': reportId,
        'bufferSize': bufferSize,
      },
    );
  }

  @override
  Future<void> sendFeatureReport(
    Uint8List data, {
    int reportId = 0x00,
  }) async {
    _ensureOpen();
    await _invokeVoid(
      'sendFeatureReport',
      <String, Object?>{
        'data': data,
        'reportId': reportId,
      },
    );
  }

  @override
  Future<void> sendOutputReport(
    Uint8List data, {
    int reportId = 0x00,
  }) async {
    _ensureOpen();
    await _invokeVoid(
      'sendOutputReport',
      <String, Object?>{
        'data': data,
        'reportId': reportId,
      },
    );
  }

  @override
  Future<String> getIndexedString(int index, {int maxLength = 256}) async {
    _ensureOpen();

    try {
      return await _channel.invokeMethod<String>(
            'getIndexedString',
            <String, Object?>{
              'path': path,
              'index': index,
              'maxLength': maxLength,
            },
          ) ??
          '';
    } on PlatformException catch (error) {
      throw _mapException(error);
    }
  }

  @override
  Future<HidReportDescriptor> getReportDescriptor() async {
    _ensureOpen();

    final rawBytes = await _invokeBytes('getReportDescriptor');
    final parser = HidReportDescriptorParser();
    return parser.parse(rawBytes);
  }

  void _ensureOpen() {
    if (!isOpen) {
      throw StateError('Device is not open.');
    }
  }

  Future<void> _invokeVoid(
    String method, [
    Map<String, Object?> arguments = const <String, Object?>{},
  ]) async {
    try {
      await _channel.invokeMethod<void>(
        method,
        <String, Object?>{
          'path': path,
          ...arguments,
        },
      );
    } on PlatformException catch (error) {
      throw _mapException(error);
    }
  }

  Future<Uint8List> _invokeBytes(
    String method, [
    Map<String, Object?> arguments = const <String, Object?>{},
  ]) async {
    try {
      return await _channel.invokeMethod<Uint8List>(
            method,
            <String, Object?>{
              'path': path,
              ...arguments,
            },
          ) ??
          Uint8List(0);
    } on PlatformException catch (error) {
      throw _mapException(error);
    }
  }

  Exception _mapException(PlatformException error) {
    if (error.code == 'TIMEOUT') {
      return TimeoutException(error.message ?? 'Timed out while reading HID report.');
    }

    return HidException(error.message ?? 'HID operation failed (${error.code}).');
  }
}

