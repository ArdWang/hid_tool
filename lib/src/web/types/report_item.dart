/// HID report item descriptor.
///
/// Describes a field within a report (size, count, usages, logical ranges).

import 'dart:js_interop';

import '../interop/js_interop.dart';
import 'unit_system.dart';

class ReportItem {
  /// Whether this item represents an array of values.
  final bool isArray;

  /// Whether this item represents a constant value.
  final bool isConstant;

  /// Whether this item represents a volatile value.
  final bool isVolatile;

  /// Whether this item uses a usage range (usageMinimum/usageMaximum).
  /// If true, usageMinimum and usageMaximum define the range.
  /// If false, usages contains the list of usage values.
  final bool isRange;

  /// Whether this item supports a null state.
  final bool hasNull;

  /// Whether this item contains buffered bytes.
  final bool isBufferedBytes;

  /// Whether this item uses absolute coordinates.
  final bool isAbsolute;

  /// Whether this item can wrap around from max to min.
  final bool wrap;

  /// Whether this item has a linear relationship between logical and physical values.
  final bool isLinear;

  /// Whether this item has a preferred state.
  final bool hasPreferredState;

  /// List of usage values associated with this item.
  final List<int>? usages;

  /// Minimum usage value (if usages is a range).
  final int? usageMinimum;

  /// Maximum usage value (if usages is a range).
  final int? usageMaximum;

  /// Size of this field in bits.
  final int reportSize;

  /// Number of fields of this type.
  final int reportCount;

  /// Unit exponent for physical values.
  final int? unitExponent;

  /// Unit system for physical measurements.
  final UnitSystem? unitSystem;

  /// Unit factor exponent for length (e.g., centimeters, inches).
  final int? unitFactorLengthExponent;

  /// Unit factor exponent for mass (e.g., grams, slugs).
  final int? unitFactorMassExponent;

  /// Unit factor exponent for time (e.g., seconds).
  final int? unitFactorTimeExponent;

  /// Unit factor exponent for temperature (e.g., kelvin, fahrenheit).
  final int? unitFactorTemperatureExponent;

  /// Unit factor exponent for current (e.g., amperes).
  final int? unitFactorCurrentExponent;

  /// Unit factor exponent for luminous intensity (e.g., candelas).
  final int? unitFactorLuminousIntensityExponent;

  /// Minimum logical value for this item.
  final int logicalMinimum;

  /// Maximum logical value for this item.
  final int logicalMaximum;

  /// Minimum physical value (in specified units).
  final int? physicalMinimum;

  /// Maximum physical value (in specified units).
  final int? physicalMaximum;

  /// String descriptors associated with this item.
  final List<String>? strings;

  /// Creates a HID report item from individual properties.
  const ReportItem({
    required this.isArray,
    required this.isConstant,
    required this.isVolatile,
    required this.isRange,
    required this.hasNull,
    required this.isBufferedBytes,
    required this.isAbsolute,
    required this.wrap,
    required this.isLinear,
    required this.hasPreferredState,
    this.usages,
    this.usageMinimum,
    this.usageMaximum,
    required this.reportSize,
    required this.reportCount,
    this.unitExponent,
    this.unitSystem,
    this.unitFactorLengthExponent,
    this.unitFactorMassExponent,
    this.unitFactorTimeExponent,
    this.unitFactorTemperatureExponent,
    this.unitFactorCurrentExponent,
    this.unitFactorLuminousIntensityExponent,
    required this.logicalMinimum,
    required this.logicalMaximum,
    this.physicalMinimum,
    this.physicalMaximum,
    this.strings,
  });

  /// Creates a [ReportItem] from a JavaScript ReportItem object.
  factory ReportItem.fromJS(JSReportItem jsItem) {
    final jsUsages = jsItem.usages;
    final usagesList = jsUsages?.toDart
        .map((usage) => usage.toDartInt)
        .toList();

    final jsStrings = jsItem.strings;
    final stringsList = jsStrings?.toDart.map((str) => str.toDart).toList();

    return ReportItem(
      isArray: jsItem.isArray,
      isConstant: jsItem.isConstant,
      isVolatile: jsItem.isVolatile,
      isRange: jsItem.isRange,
      hasNull: jsItem.hasNull,
      isBufferedBytes: jsItem.isBufferedBytes,
      isAbsolute: jsItem.isAbsolute,
      wrap: jsItem.wrap,
      isLinear: jsItem.isLinear,
      hasPreferredState: jsItem.hasPreferredState,
      usages: usagesList,
      usageMinimum: jsItem.usageMinimum,
      usageMaximum: jsItem.usageMaximum,
      reportSize: jsItem.reportSize,
      reportCount: jsItem.reportCount,
      unitExponent: jsItem.unitExponent,
      unitSystem: UnitSystem.fromString(jsItem.unitSystem),
      unitFactorLengthExponent: jsItem.unitFactorLengthExponent,
      unitFactorMassExponent: jsItem.unitFactorMassExponent,
      unitFactorTimeExponent: jsItem.unitFactorTimeExponent,
      unitFactorTemperatureExponent: jsItem.unitFactorTemperatureExponent,
      unitFactorCurrentExponent: jsItem.unitFactorCurrentExponent,
      unitFactorLuminousIntensityExponent:
          jsItem.unitFactorLuminousIntensityExponent,
      logicalMinimum: jsItem.logicalMinimum,
      logicalMaximum: jsItem.logicalMaximum,
      physicalMinimum: jsItem.physicalMinimum,
      physicalMaximum: jsItem.physicalMaximum,
      strings: stringsList,
    );
  }

  @override
  String toString() {
    return 'ReportItem('
        'reportSize: $reportSize, '
        'reportCount: $reportCount, '
        'logicalMin: $logicalMinimum, '
        'logicalMax: $logicalMaximum, '
        'usages: $usages'
        ')';
  }
}
