/// HID report metadata.
///
/// Contains `reportId` and the list of `items` describing the report layout.

import 'dart:js_interop';

import '../interop/js_interop.dart';
import '../utils/collection_utils.dart';
import 'report_item.dart';

class ReportInfo {
  /// The report ID, or 0 if the device does not use report IDs.
  ///
  /// Report IDs are used to distinguish between different report types
  /// when a device has multiple reports of the same kind.
  final int reportId;

  /// List of items that make up this report.
  ///
  /// Each item represents a field in the report with its own characteristics
  /// and value range.
  final List<ReportItem> items;

  /// Creates a HID report info object.
  const ReportInfo({required this.reportId, required this.items});

  /// Creates a [ReportInfo] from a JavaScript ReportInfo object.
  factory ReportInfo.fromJS(JSReportInfo jsInfo) {
    final jsItems = jsInfo.items.toDart;
    final itemsList = jsItems.map((item) => ReportItem.fromJS(item)).toList();

    return ReportInfo(reportId: jsInfo.reportId, items: itemsList);
  }

  @override
  String toString() {
    return 'ReportInfo('
        'reportId: $reportId, '
        'items: ${items.length} items'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ReportInfo &&
        other.reportId == reportId &&
        listEquals(other.items, items);
  }

  @override
  int get hashCode {
    return Object.hash(reportId, Object.hashAll(items));
  }
}
