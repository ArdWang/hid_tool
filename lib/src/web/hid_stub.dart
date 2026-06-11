/// Stub file for non-web platforms.
import 'dart:typed_data';

/// WebHID stub class for non-web platforms.
class WebHID {
  static bool get isSupported => false;
  static WebHID? get instance => null;
}

/// Device stub for non-web platforms.
class Device {
  bool get opened => false;
  int get vendorId => 0;
  int get productId => 0;
  String get productName => '';
  List<CollectionInfo> get collections => [];

  Future<void> open() => throw UnsupportedError('WebHID is not available');
  Future<void> close() => throw UnsupportedError('WebHID is not available');
  Future<void> sendReport(int reportId, Uint8List data) =>
      throw UnsupportedError('WebHID is not available');
  Future<void> sendFeatureReport(int reportId, Uint8List data) =>
      throw UnsupportedError('WebHID is not available');
  Future<Uint8List> receiveFeatureReport(int reportId) =>
      throw UnsupportedError('WebHID is not available');

  Stream<InputReportEvent> get onInputReport =>
      throw UnsupportedError('WebHID is not available');
}

/// InputReportEvent stub.
class InputReportEvent {
  int get reportId => 0;
  Uint8List get data => Uint8List(0);
}

/// CollectionInfo stub.
class CollectionInfo {
  int get usagePage => 0;
  int get usage => 0;
  int get type => 0;
}

/// RequestOptions stub.
class RequestOptions {
  final List<DeviceFilter> filters;
  RequestOptions({required this.filters});
}

/// DeviceFilter stub.
class DeviceFilter {
  final int? vendorId;
  final int? productId;
  final int? usagePage;
  final int? usage;
  DeviceFilter({this.vendorId, this.productId, this.usagePage, this.usage});
}
