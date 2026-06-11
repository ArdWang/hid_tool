import 'dart:ffi';
import 'dart:io' show Platform;

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
  /// Converts a wchar_t* to a Dart [String].
  ///
  /// On Windows, wchar_t is 2 bytes (UTF-16), so we cast to [Utf16].
  /// On macOS/Linux/Android, wchar_t is 4 bytes (UTF-32), so we read
  /// as [Uint32] and decode via [String.fromCharCodes].
  String toDartString({int? length}) {
    _ensureNotNullptr('toDartString');
    if (Platform.isWindows) {
      // Windows: wchar_t is 16-bit (UTF-16)
      if (length == null) {
        return cast<Utf16>().toDartString();
      } else {
        RangeError.checkNotNegative(length, 'length');
        return cast<Utf16>().toDartString(length: length);
      }
    } else {
      // macOS/Linux/Android: wchar_t is 32-bit (UTF-32LE)
      return _toDartStringFromUtf32(length: length);
    }
  }

  /// Reads wchar_t* as UTF-32LE (used on non-Windows platforms where
  /// wchar_t is 4 bytes).
  String _toDartStringFromUtf32({int? length}) {
    final ptr32 = cast<Uint32>();
    if (length != null) {
      RangeError.checkNotNegative(length, 'length');
      return String.fromCharCodes(ptr32.asTypedList(length));
    }
    // Read until null terminator (Uint32 value == 0)
    final codes = <int>[];
    var i = 0;
    while (true) {
      final code = ptr32[i];
      if (code == 0) break;
      codes.add(code);
      i++;
    }
    return String.fromCharCodes(codes);
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
