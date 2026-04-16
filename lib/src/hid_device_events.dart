import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Represents a HID device connection event.
class HidDeviceEvent {
  /// The device path identifier
  final String path;

  /// The vendor ID of the device
  final int? vendorId;

  /// The product ID of the device
  final int? productId;

  /// The timestamp of the event
  final DateTime timestamp;

  HidDeviceEvent({
    required this.path,
    this.vendorId,
    this.productId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'HidDeviceEvent(path: $path, vendorId: 0x${vendorId?.toRadixString(16) ?? 'unknown'}, '
        'productId: 0x${productId?.toRadixString(16) ?? 'unknown'})';
  }
}

/// Callback type for device event listeners
typedef HidDeviceEventHandler = void Function(HidDeviceEvent event);

/// HID device connection/disconnection event stream.
///
/// This class provides a stream-based API for listening to HID device
/// connection and disconnection events without polling.
///
/// Example usage:
/// ```dart
/// // Listen for device connected events
/// HidDeviceEvents.onConnected.listen((event) {
///   print('Device connected: ${event.path}');
/// });
///
/// // Listen for device disconnected events
/// HidDeviceEvents.onDisconnected.listen((event) {
///   print('Device disconnected: ${event.path}');
/// });
///
/// // Stop listening when no longer needed
/// HidDeviceEvents.stopListening();
/// ```
class HidDeviceEvents {
  static const MethodChannel _channel = MethodChannel('hid_tool');

  static final StreamController<HidDeviceEvent> _connectedController =
      StreamController<HidDeviceEvent>.broadcast();

  static final StreamController<HidDeviceEvent> _disconnectedController =
      StreamController<HidDeviceEvent>.broadcast();

  static bool _isListening = false;

  /// Stream of device connected events
  static Stream<HidDeviceEvent> get onConnected => _connectedController.stream;

  /// Stream of device disconnected events
  static Stream<HidDeviceEvent> get onDisconnected =>
      _disconnectedController.stream;

  /// Start listening for HID device connection/disconnection events.
  ///
  /// Returns a [StreamSubscription] that can be used to cancel listening.
  static Future<void> startListening() async {
    if (_isListening) {
      return;
    }

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onDeviceConnected':
          final event = _parseDeviceEvent(call.arguments);
          if (!_connectedController.isClosed) {
            _connectedController.add(event);
          }
          break;
        case 'onDeviceDisconnected':
          final event = _parseDeviceEvent(call.arguments);
          if (!_disconnectedController.isClosed) {
            _disconnectedController.add(event);
          }
          break;
      }
    });

    try {
      if (Platform.isWindows ||
          Platform.isMacOS ||
          Platform.isLinux ||
          Platform.isAndroid) {
        await _channel.invokeMethod('startListening');
        _isListening = true;
      } else {
        debugPrint("The current platform is not supported for HID device events.");
      }
    } on PlatformException catch (e) {
      debugPrint("Error starting HID device event listening: ${e.message}");
    }
  }

  /// Stop listening for HID device events.
  static Future<void> stopListening() async {
    if (!_isListening) {
      return;
    }

    try {
      if (Platform.isWindows ||
          Platform.isMacOS ||
          Platform.isLinux ||
          Platform.isAndroid) {
        await _channel.invokeMethod('stopListening');
        _isListening = false;
      }
    } on PlatformException catch (e) {
      debugPrint("Error stopping HID device event listening: ${e.message}");
    }
  }

  /// Parse device event arguments from platform channel
  static HidDeviceEvent _parseDeviceEvent(dynamic arguments) {
    if (arguments is Map) {
      return HidDeviceEvent(
        path: arguments['path'] as String? ?? '',
        vendorId: arguments['vendorId'] as int?,
        productId: arguments['productId'] as int?,
      );
    } else if (arguments is String) {
      // Fallback for backward compatibility - just path string
      return HidDeviceEvent(path: arguments);
    }
    return HidDeviceEvent(path: '');
  }

  /// Dispose of the stream controllers
  static void dispose() {
    _connectedController.close();
    _disconnectedController.close();
  }
}
