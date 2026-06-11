/// HID unit system enumeration.
///
/// Small enum for known HID unit system string values.

enum UnitSystem {
  /// No unit system specified.
  none('none'),

  /// SI Linear unit system (centimeter, gram, seconds, kelvin, ampere, candela).
  siLinear('si-linear'),

  /// SI Rotation unit system (radians, gram, seconds, kelvin, ampere, candela).
  siRotation('si-rotation'),

  /// English Linear unit system (inch, slug, seconds, fahrenheit, ampere, candela).
  englishLinear('english-linear'),

  /// English Rotation unit system (degrees, slug, seconds, fahrenheit, ampere, candela).
  englishRotation('english-rotation'),

  /// A vendor-defined unit system.
  vendorDefined('vendor-defined'),

  /// Reserved unit system value.
  reserved('reserved');

  /// The string value of the unit system as used in the WebHID API.
  final String value;

  const UnitSystem(this.value);

  /// Creates a [UnitSystem] from a string value.
  ///
  /// Returns null if the value doesn't match any known unit system.
  static UnitSystem? fromString(String? value) {
    if (value == null) {
      return null;
    }

    for (final system in UnitSystem.values) {
      if (system.value == value) {
        return system;
      }
    }
    return null;
  }

  @override
  String toString() => value;
}
