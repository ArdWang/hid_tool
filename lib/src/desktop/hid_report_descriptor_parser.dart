import 'dart:typed_data';

import 'package:hid_tool/src/hid_device.dart';

/// Parser for HID report descriptors.
///
/// Parses raw HID report descriptor bytes into a structured representation
/// with collections, inputs, outputs, and features.
class HidReportDescriptorParser {
  // HID Report Descriptor Item Tags
  static const int _mainInputTag = 0x80;
  static const int _mainOutputTag = 0x90;
  static const int _mainFeatureTag = 0xB0;
  static const int _mainCollectionTag = 0xA0;
  static const int _mainCollectionEndTag = 0xC0;

  static const int _globalUsagePageTag = 0x04;
  static const int _globalLogicalMinimumTag = 0x14;
  static const int _globalLogicalMaximumTag = 0x24;
  static const int _globalPhysicalMinimumTag = 0x34;
  static const int _globalPhysicalMaximumTag = 0x44;
  static const int _globalUnitExponentTag = 0x54;
  static const int _globalUnitTag = 0x64;
  static const int _globalReportSizeTag = 0x74;
  static const int _globalReportIdTag = 0x84;
  static const int _globalReportCountTag = 0x94;
  static const int _globalPushTag = 0xA4;
  static const int _globalPopTag = 0xB4;

  static const int _localUsageTag = 0x08;
  static const int _localUsageMinimumTag = 0x18;
  static const int _localUsageMaximumTag = 0x28;
  static const int _localDesignatorIndexTag = 0x38;
  static const int _localStringIndexTag = 0x78;

  /// Parse raw HID report descriptor bytes into a structured representation.
  HidReportDescriptor parse(Uint8List rawBytes) {
    final state = _ParserState();
    int offset = 0;

    while (offset < rawBytes.length) {
      final item = _parseItem(rawBytes, offset);
      offset += item.totalLength;

      _processItem(item, state);
    }

    return HidReportDescriptor(
      rawBytes: rawBytes,
      collections: state.collections,
      inputs: state.inputs,
      outputs: state.outputs,
      features: state.features,
    );
  }

  _HidDescriptorItem _parseItem(Uint8List bytes, int offset) {
    final prefix = bytes[offset];
    final tag = prefix & 0xFC;
    final type = (prefix >> 2) & 0x03;
    // Size type: 0=0 bytes, 1=1 byte, 2=2 bytes, 3=4 bytes
    final sizeType = prefix & 0x03;
    final dataSize = sizeType == 3 ? 4 : sizeType;

    int data = 0;
    for (int i = 0; i < dataSize && offset + 1 + i < bytes.length; i++) {
      data |= (bytes[offset + 1 + i] << (8 * i));
    }

    return _HidDescriptorItem(
      tag: tag,
      type: type,
      size: dataSize,
      data: data,
      totalLength: 1 + dataSize,
    );
  }

  void _processItem(_HidDescriptorItem item, _ParserState state) {
    switch (item.tag) {
      case _mainInputTag:
        _processMainItem(item, state, HidReportType.input);
        break;
      case _mainOutputTag:
        _processMainItem(item, state, HidReportType.output);
        break;
      case _mainFeatureTag:
        _processMainItem(item, state, HidReportType.feature);
        break;
      case _mainCollectionTag:
        _processCollection(item, state);
        break;
      case _mainCollectionEndTag:
        _processCollectionEnd(state);
        break;

      // Global items
      case _globalUsagePageTag:
        state.usagePage = item.data;
        break;
      case _globalLogicalMinimumTag:
        state.logicalMinimum = _toSigned(item.data, item.size);
        break;
      case _globalLogicalMaximumTag:
        state.logicalMaximum = _toSigned(item.data, item.size);
        break;
      case _globalPhysicalMinimumTag:
        state.physicalMinimum = _toSigned(item.data, item.size);
        break;
      case _globalPhysicalMaximumTag:
        state.physicalMaximum = _toSigned(item.data, item.size);
        break;
      case _globalUnitExponentTag:
        state.unitExponent = item.data;
        break;
      case _globalUnitTag:
        state.unit = item.data;
        break;
      case _globalReportSizeTag:
        state.reportSize = item.data;
        break;
      case _globalReportIdTag:
        state.reportId = item.data;
        break;
      case _globalReportCountTag:
        state.reportCount = item.data;
        break;
      case _globalPushTag:
        state.pushState();
        break;
      case _globalPopTag:
        state.popState();
        break;

      // Local items
      case _localUsageTag:
        state.usage = item.data;
        state.usageMinimum = null;
        state.usageMaximum = null;
        break;
      case _localUsageMinimumTag:
        state.usageMinimum = item.data;
        break;
      case _localUsageMaximumTag:
        state.usageMaximum = item.data;
        break;
      case _localDesignatorIndexTag:
        state.designatorIndex = item.data;
        break;
      case _localStringIndexTag:
        state.stringIndex = item.data;
        break;
    }
  }

  void _processMainItem(
      _HidDescriptorItem item, _ParserState state, HidReportType reportType) {
    final flags = item.data;
    // Flags interpretation:
    // Bit 0: Data/Constant (0=Data, 1=Constant)
    // Bit 1: Variable/Array (0=Array, 1=Variable)
    // Bit 2: Absolute/Relative (0=Absolute, 1=Relative)
    // Bit 3: No Wrap/With Wrap (0=No Wrap, 1=With Wrap)
    // Bit 4: Linear/NonLinear (0=Linear, 1=NonLinear)
    // Bit 5: Preferred State/Null (0=No Null, 1=Null)
    // Bit 6: NonVolatile/Volatile (0=NonVolatile, 1=Volatile)
    // Bit 7: Bit Field/Buffered Bytes (0=Bit Field, 1=Buffered Bytes)
    final isVariable = (flags & 0x02) != 0;
    final isRelative = (flags & 0x04) != 0;
    final hasNull = (flags & 0x20) != 0;

    // Create report items
    for (int i = 0; i < state.reportCount; i++) {
      final reportItem = HidReportItem(
        reportType: reportType,
        reportId: state.reportId,
        usagePage: state.usagePage,
        usage: state.usage != null ? state.usage! + i : null,
        usageMinimum: state.usageMinimum,
        usageMaximum: state.usageMaximum,
        logicalMinimum: state.logicalMinimum,
        logicalMaximum: state.logicalMaximum,
        physicalMinimum: state.physicalMinimum,
        physicalMaximum: state.physicalMaximum,
        reportSize: state.reportSize,
        reportCount: 1,
        unitExponent: state.unitExponent,
        unit: state.unit,
        designatorIndex: state.designatorIndex,
        stringIndex: state.stringIndex,
        isArray: !isVariable,
        isAbsolute: !isRelative,
        hasNull: hasNull,
        isVariable: isVariable,
        bitPosition: state.currentBitPosition,
      );

      state.currentBitPosition += state.reportSize;

      // Add to appropriate list
      switch (reportType) {
        case HidReportType.input:
          state.inputs.add(reportItem);
          break;
        case HidReportType.output:
          state.outputs.add(reportItem);
          break;
        case HidReportType.feature:
          state.features.add(reportItem);
          break;
      }

      // Add to current collection
      if (state.currentCollection != null) {
        state.currentCollection!.items.add(reportItem);
      }
    }
  }

  void _processCollection(_HidDescriptorItem item, _ParserState state) {
    final collectionType = item.data & 0xFF;
    final usagePage = state.usagePage;
    final usage = state.usage ?? 0;

    final collection = HidCollection(
      usagePage: usagePage,
      usage: usage,
      collectionType: collectionType,
      children: [],
      items: [],
      parent: state.currentCollection,
    );

    // Add to parent's children or top-level collections
    if (state.currentCollection != null) {
      state.currentCollection!.children.add(collection);
    } else {
      state.collections.add(collection);
    }

    // Push to stack
    state.collectionStack.add(collection);
  }

  void _processCollectionEnd(_ParserState state) {
    if (state.collectionStack.isNotEmpty) {
      state.collectionStack.removeLast();
    }
  }

  int _toSigned(int value, int byteSize) {
    if (byteSize < 4) {
      final maxVal = 1 << (8 * byteSize - 1);
      if (value >= maxVal) {
        return value - (2 * maxVal);
      }
    }
    return value;
  }
}

class _HidDescriptorItem {
  final int tag;
  final int type;
  final int size;
  final int data;
  final int totalLength;

  _HidDescriptorItem({
    required this.tag,
    required this.type,
    required this.size,
    required this.data,
    required this.totalLength,
  });
}

class _ParserState {
  int usagePage = 0;
  int? usage;
  int? usageMinimum;
  int? usageMaximum;
  int? logicalMinimum;
  int? logicalMaximum;
  int? physicalMinimum;
  int? physicalMaximum;
  int? unitExponent;
  int? unit;
  int reportSize = 0;
  int reportId = 0;
  int reportCount = 0;
  int? designatorIndex;
  int? stringIndex;

  int currentBitPosition = 0;

  final List<HidCollection> collections = [];
  final List<HidReportItem> inputs = [];
  final List<HidReportItem> outputs = [];
  final List<HidReportItem> features = [];

  final List<HidCollection> collectionStack = [];

  HidCollection? get currentCollection =>
      collectionStack.isNotEmpty ? collectionStack.last : null;

  // State stack for push/pop
  final List<_ParserStateSnapshot> _stateStack = [];

  void pushState() {
    _stateStack.add(_ParserStateSnapshot(
      usagePage: usagePage,
      logicalMinimum: logicalMinimum,
      logicalMaximum: logicalMaximum,
      physicalMinimum: physicalMinimum,
      physicalMaximum: physicalMaximum,
      unitExponent: unitExponent,
      unit: unit,
      reportSize: reportSize,
      reportCount: reportCount,
    ));
  }

  void popState() {
    if (_stateStack.isNotEmpty) {
      final snapshot = _stateStack.removeLast();
      usagePage = snapshot.usagePage;
      logicalMinimum = snapshot.logicalMinimum;
      logicalMaximum = snapshot.logicalMaximum;
      physicalMinimum = snapshot.physicalMinimum;
      physicalMaximum = snapshot.physicalMaximum;
      unitExponent = snapshot.unitExponent;
      unit = snapshot.unit;
      reportSize = snapshot.reportSize;
      reportCount = snapshot.reportCount;
    }
  }
}

class _ParserStateSnapshot {
  final int usagePage;
  final int? logicalMinimum;
  final int? logicalMaximum;
  final int? physicalMinimum;
  final int? physicalMaximum;
  final int? unitExponent;
  final int? unit;
  final int reportSize;
  final int reportCount;

  _ParserStateSnapshot({
    required this.usagePage,
    this.logicalMinimum,
    this.logicalMaximum,
    this.physicalMinimum,
    this.physicalMaximum,
    this.unitExponent,
    this.unit,
    required this.reportSize,
    required this.reportCount,
  });
}
