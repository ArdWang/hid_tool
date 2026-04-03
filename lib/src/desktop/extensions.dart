import 'dart:ffi';

import 'package:ffi/ffi.dart';

extension CharPointerToString on Pointer<Char> {
  String toDartString({int? length}) {
    _ensureNotNullptr('toDartString');
    if (length == null) {
      return cast<Utf8>().toDartString();
    } else {
      RangeError.checkNotNegative(length, 'length');
      return cast<Utf8>().toDartString(length: length);
    }
  }

  void _ensureNotNullptr(String operation) {
    if (this == nullptr) {
      throw UnsupportedError(
          "Operation '$operation' not allowed on a 'nullptr'.");
    }
  }
}

extension WCharPointerToString on Pointer<WChar> {
  String toDartString({int? length}) {
    _ensureNotNullptr('toDartString');
    if (length == null) {
      return cast<Utf16>().toDartString();
    } else {
      RangeError.checkNotNegative(length, 'length');
      return cast<Utf16>().toDartString(length: length);
    }
  }

  void _ensureNotNullptr(String operation) {
    if (this == nullptr) {
      throw UnsupportedError(
          "Operation '$operation' not allowed on a 'nullptr'.");
    }
  }
}

extension StringToChar on String {
  Pointer<Char> toCharPointer({Allocator allocator = malloc}) {
    final units = codeUnits;
    final Pointer<Char> result = allocator<Char>(units.length + 1);
    for (var i = 0; i < units.length; i++) {
      result[i] = units[i];
    }
    result[units.length] = 0;
    return result;
  }

  Pointer<WChar> toWCharPointer({Allocator allocator = malloc}) {
    final units = codeUnits;
    final Pointer<WChar> result = allocator<WChar>(units.length + 1);
    for (var i = 0; i < units.length; i++) {
      result[i] = units[i];
    }
    result[units.length] = 0;
    return result;
  }
}
