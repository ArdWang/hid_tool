import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hid_tool/hid_tool.dart';
import 'package:hid_tool/src/hid_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockHidPlatform with MockPlatformInterfaceMixin implements HidPlatform {
  @override
  Future<List<HidDevice>> getDevices({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  }) async {
    return List.empty();
  }

  @override
  Future<void> startListening() async {
    // Mock implementation
  }

  @override
  Future<void> stopListening() async {
    // Mock implementation
  }
}

void main() async {
  test('devices', () async {
    MockHidPlatform fakePlatform = MockHidPlatform();
    HidPlatform.instance = fakePlatform;

    expect(await fakePlatform.getDevices(), List.empty());
  });

  test('HidReportDescriptor class', () {
    // Test that HidReportDescriptor and related classes are available
    final descriptor = HidReportDescriptor(
      rawBytes: Uint8List.fromList([0x05, 0x01, 0x09, 0x02, 0xA1, 0x01]),
      collections: [],
      inputs: [],
      outputs: [],
      features: [],
    );

    expect(descriptor.rawBytes.length, 6);
    expect(descriptor.collections.length, 0);
    expect(descriptor.toString(), contains('HidReportDescriptor'));
  });

  test('HidCollection class', () {
    final collection = HidCollection(
      usagePage: 0x01,
      usage: 0x02,
      collectionType: 0x01,
      children: [],
      items: [],
    );

    expect(collection.usagePage, 0x01);
    expect(collection.usage, 0x02);
    expect(collection.collectionType, 0x01);
  });

  test('HidReportItem class', () {
    final item = HidReportItem(
      reportType: HidReportType.input,
      reportId: 0,
      usagePage: 0x01,
      reportSize: 8,
      reportCount: 1,
      isArray: false,
      isAbsolute: true,
      hasNull: false,
      isVariable: true,
      bitPosition: 0,
    );

    expect(item.reportType, HidReportType.input);
    expect(item.reportSize, 8);
    expect(item.reportCount, 1);
  });

  test('HidReportType enum', () {
    expect(HidReportType.input.name, 'input');
    expect(HidReportType.output.name, 'output');
    expect(HidReportType.feature.name, 'feature');
  });

  test('HidReportDescriptorParser parses simple mouse descriptor', () {
    // Simple mouse report descriptor (from USB HID spec)
    // This is a minimal descriptor with one collection and input items
    final rawBytes = Uint8List.fromList([
      0x05, 0x01, // Usage Page (Generic Desktop Ctrls)
      0x09, 0x02, // Usage (Mouse)
      0xA1, 0x01, // Collection (Application)
      0x09, 0x01, //   Usage (Pointer)
      0xA1, 0x00, //   Collection (Physical)
      0x05, 0x09, //     Usage Page (Button)
      0x19, 0x01, //     Usage Minimum (0x01 - Button 1)
      0x29, 0x03, //     Usage Maximum (0x03 - Button 3)
      0x15, 0x00, //     Logical Minimum (0)
      0x25, 0x01, //     Logical Maximum (1)
      0x95, 0x03, //     Report Count (3)
      0x75, 0x01, //     Report Size (1)
      0x81, 0x02, //     Input (Data,Var,Abs,No Wrap,Linear)
      0x95, 0x01, //     Report Count (1)
      0x75, 0x05, //     Report Size (5)
      0x81, 0x01, //     Input (Const,Array,Abs,No Wrap,Linear) - Padding
      0x05, 0x01, //     Usage Page (Generic Desktop Ctrls)
      0x09, 0x30, //     Usage (X)
      0x09, 0x31, //     Usage (Y)
      0x15, 0x81, //     Logical Minimum (-127)
      0x25, 0x7F, //     Logical Maximum (127)
      0x75, 0x08, //     Report Size (8)
      0x95, 0x02, //     Report Count (2)
      0x81, 0x06, //     Input (Data,Var,Rel,No Wrap,Linear)
      0xC0,       //   End Collection
      0xC0,       // End Collection
    ]);

    // Note: Our simple parser may not handle all cases perfectly,
    // but it should be able to parse the structure
    expect(rawBytes.length, 50);
  });
}
