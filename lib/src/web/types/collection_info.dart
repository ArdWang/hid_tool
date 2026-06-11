/// HID collection metadata.
///
/// Simple data holder for collection usage, type and reports.

import 'dart:js_interop';

import '../interop/js_interop.dart';
import 'report_info.dart';

class CollectionInfo {
  /// The usage page of this collection.
  ///
  /// The usage page categorizes the type of device or control
  /// (e.g., Generic Desktop, Consumer, etc.).
  final int usagePage;

  /// The usage ID within the usage page.
  ///
  /// The usage identifies the specific function or control
  /// (e.g., Mouse, Keyboard, Joystick).
  final int usage;

  /// The collection type.
  ///
  /// Common types include:
  /// - 0x00: Physical
  /// - 0x01: Application
  /// - 0x02: Logical
  /// - 0x03: Report
  /// - 0x04: Named Array
  /// - 0x05: Usage Switch
  /// - 0x06: Usage Modifier
  final int type;

  /// Child collections nested within this collection.
  final List<CollectionInfo>? children;

  /// Input reports in this collection.
  ///
  /// Input reports are sent from the device to the host.
  final List<ReportInfo>? inputReports;

  /// Output reports in this collection.
  ///
  /// Output reports are sent from the host to the device.
  final List<ReportInfo>? outputReports;

  /// Feature reports in this collection.
  ///
  /// Feature reports can be sent in either direction and typically
  /// represent device configuration or state.
  final List<ReportInfo>? featureReports;

  /// Creates a HID collection info object.
  const CollectionInfo({
    required this.usagePage,
    required this.usage,
    required this.type,
    this.children,
    this.inputReports,
    this.outputReports,
    this.featureReports,
  });

  /// Creates a [CollectionInfo] from a JavaScript CollectionInfo object.
  factory CollectionInfo.fromJS(JSCollectionInfo jsCollection) {
    // Convert children
    final jsChildren = jsCollection.children;
    final childrenList = jsChildren?.toDart
        .map((child) => CollectionInfo.fromJS(child))
        .toList();

    // Convert input reports
    final jsInputReports = jsCollection.inputReports;
    final inputReportsList = jsInputReports?.toDart
        .map((report) => ReportInfo.fromJS(report))
        .toList();

    // Convert output reports
    final jsOutputReports = jsCollection.outputReports;
    final outputReportsList = jsOutputReports?.toDart
        .map((report) => ReportInfo.fromJS(report))
        .toList();

    // Convert feature reports
    final jsFeatureReports = jsCollection.featureReports;
    final featureReportsList = jsFeatureReports?.toDart
        .map((report) => ReportInfo.fromJS(report))
        .toList();

    return CollectionInfo(
      usagePage: jsCollection.usagePage ?? 0,
      usage: jsCollection.usage ?? 0,
      type: jsCollection.type,
      children: childrenList,
      inputReports: inputReportsList,
      outputReports: outputReportsList,
      featureReports: featureReportsList,
    );
  }

  /// Returns the collection type name.
  String get typeName {
    switch (type) {
      case 0x00:
        return 'Physical';
      case 0x01:
        return 'Application';
      case 0x02:
        return 'Logical';
      case 0x03:
        return 'Report';
      case 0x04:
        return 'Named Array';
      case 0x05:
        return 'Usage Switch';
      case 0x06:
        return 'Usage Modifier';
      default:
        return 'Unknown (0x${type.toRadixString(16)})';
    }
  }

  @override
  String toString() {
    return 'CollectionInfo('
        'usagePage: 0x${usagePage.toRadixString(16)}, '
        'usage: 0x${usage.toRadixString(16)}, '
        'type: $typeName, '
        'children: ${children?.length ?? 0}, '
        'inputReports: ${inputReports?.length ?? 0}, '
        'outputReports: ${outputReports?.length ?? 0}, '
        'featureReports: ${featureReports?.length ?? 0}'
        ')';
  }
}
