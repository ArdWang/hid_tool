/// Request options for device permission prompt.
///
/// Contains lists of `filters` and optional `exclusionFilters`.

import 'dart:js_interop';

import '../interop/js_interop.dart';
import '../utils/collection_utils.dart';
import 'device_filter.dart';

class RequestOptions {
  /// A list of filters to match devices against.
  ///
  /// If a device matches any filter in this list, it will be shown in the
  /// permission prompt. If this list is empty or all filters are invalid,
  /// all devices will be shown.
  final List<DeviceFilter> filters;

  /// A list of exclusion filters.
  ///
  /// Devices matching any exclusion filter will not be shown in the
  /// permission prompt, even if they match a filter in [filters].
  final List<DeviceFilter>? exclusionFilters;

  /// Creates options for requesting HID devices.
  ///
  /// [filters] specifies which devices should be shown in the permission prompt.
  /// [exclusionFilters] specifies which devices should be excluded, even if they
  /// match a filter.
  RequestOptions({this.filters = const [], this.exclusionFilters});

  /// Converts this options object to a JavaScript object for the WebHID API.
  JSRequestOptions toJS() {
    final map = <String, Object?>{};

    map['filters'] = filters.map((f) => f.toJS()).toList().toJS;

    if (exclusionFilters != null && exclusionFilters!.isNotEmpty) {
      map['exclusionFilters'] = exclusionFilters!
          .map((f) => f.toJS())
          .toList()
          .toJS;
    }

    return map.jsify() as JSRequestOptions;
  }

  @override
  String toString() {
    return 'RequestOptions('
        'filters: $filters, '
        'exclusionFilters: $exclusionFilters'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is RequestOptions &&
        listEquals(other.filters, filters) &&
        listEquals(other.exclusionFilters, exclusionFilters);
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(filters),
      exclusionFilters != null ? Object.hashAll(exclusionFilters!) : null,
    );
  }
}
