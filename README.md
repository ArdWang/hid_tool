# hid_tool

[![pub](https://img.shields.io/badge/pub-0.0.7-blue)](https://pub.dev/packages/hid_tool)
[![license: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)

English | [中文](#中文)

---

`hid_tool` is a Flutter plugin that enables communication with HID (Human Interface Device) devices from a Flutter application.

## Acknowledgements

This project is a fork/modified version of [hid4flutter](https://github.com/vinsfortunato/hid4flutter) by vinsfortunato. We have renamed it to `hid_tool` and upgraded the underlying hidapi library to version 0.15.0 with additional methods and improvements.

Original Project: [https://github.com/vinsfortunato/hid4flutter](https://github.com/vinsfortunato/hid4flutter)

## Disclaimer

**Warning:** This plugin is currently under development, and the API may be subject to change. Use it at your own risk in a production environment.

Contributions are welcome! Feel free to submit issues and pull requests to help improve this plugin.

## Supported Platforms

- ✅ Windows
- ✅ macOS
- ✅ Linux (requires manual installation of `libhidapi-hidraw0`, see [Installation](#installation))

### Implementation Details

Desktop support (Windows/macOS/Linux) is achieved by using [hidapi](https://github.com/libusb/hidapi) (version 0.15.0) and Dart FFI.

### Planned Platform Support

Support for the following platforms is planned to be added in the near future:

- **Android**: Can be supported using MethodChannel and Android HID API.
- **Web**: Experimental WebHID API can be used to support the Web platform.

## Installation

### Step 1: Add Dependency

Add the following line to your `pubspec.yaml` file:

```yaml
dependencies:
  hid_tool: ^0.0.7
```

Replace `^0.0.7` with the latest version of the plugin.

### Step 2: Install Dependencies

Run the following command to install the dependency:

```bash
flutter pub get
```

### Step 3: Import Package

Import the `hid_tool` package in your Dart code:

```dart
import 'package:hid_tool/hid_tool.dart';
```

### Platform-Specific Notes

#### Linux

On Linux, you need to install `hidapi` manually:

```bash
sudo apt-get install libhidapi-hidraw0
```

#### macOS

On macOS, the hidapi dependency is automatically managed by CocoaPods.

#### Windows

On Windows, hidapi is compiled automatically as part of the build process.

## Example Application

A complete example application is available in the [`example/`](example/) directory. The example demonstrates:

- **Device enumeration** - List all connected HID devices
- **Event listening** - Real-time device connection/disconnection events
- **Report descriptor parsing** - Fetch and display device report descriptors
- **Device details view** - View comprehensive device information

### Running the Example

```bash
cd example
flutter pub get
flutter run
```

See [example/README.md](example/README.md) for detailed documentation.

## Usage

### Initialize and Get Devices

```dart
import 'package:hid_tool/hid_tool.dart';

// Get all connected HID devices
List<HidDevice> devices = await Hid.getDevices();

// Get devices by Vendor ID and Product ID
List<HidDevice> filteredDevices = await Hid.getDevices(
  vendorId: 0x046D,
  productId: 0xC52B,
);

// Get devices by Usage Page and Usage
List<HidDevice> usageFilteredDevices = await Hid.getDevices(
  usagePage: 0xFF00,
  usage: 0x01,
);
```

### Open and Close Device

```dart
final HidDevice device = devices.first;

try {
  // Open the device connection
  await device.open();

  // Check if device is open
  if (device.isOpen) {
    print('Device is open');
  }

  // ... perform operations ...

} finally {
  // Always close the device when done
  await device.close();
}
```

### Send Output Report

```dart
final HidDevice device = ...;

try {
  await device.open();

  // Send an Output report of 32 bytes (all zeroes)
  // The reportId is optional (default is 0x00)
  // It will be prefixed to the data as per HID rules
  Uint8List data = Uint8List(32);
  await device.sendReport(data, reportId: 0x00);

} finally {
  await device.close();
}
```

### Send Output Report (Using hidapi 0.15.0+ Method)

```dart
final HidDevice device = ...;

try {
  await device.open();

  // Use the new sendOutputReport method (hidapi 0.15.0+)
  // This sends through Interrupt OUT endpoint if available
  Uint8List data = Uint8List(32);
  await device.sendOutputReport(data, reportId: 0x00);

} finally {
  await device.close();
}
```

### Receive Input Report

```dart
final HidDevice device = ...;

try {
  await device.open();

  // Receive a report of 32 bytes with timeout of 2 seconds
  Uint8List data = await device.receiveReport(32, timeout: const Duration(seconds: 2));

  // First byte is always the reportId
  int reportId = data[0];

  print('Received report with id $reportId: $data');

} finally {
  await device.close();
}
```

### Listen to Input Stream

```dart
final HidDevice device = ...;

try {
  await device.open();

  // Listen to the input stream from the device
  device.inputStream().listen((byte) {
    print('Received byte: $byte');
  });

} finally {
  await device.close();
}
```

### Send Feature Report

```dart
final HidDevice device = ...;

try {
  await device.open();

  // Send a Feature report
  Uint8List data = Uint8List(16);
  await device.sendFeatureReport(data, reportId: 0x01);

} finally {
  await device.close();
}
```

### Receive Feature Report

```dart
final HidDevice device = ...;

try {
  await device.open();

  // Receive a Feature report
  Uint8List data = await device.receiveFeatureReport(0x01, bufferSize: 64);

  print('Feature report: $data');

} finally {
  await device.close();
}
```

### Get Device Information

```dart
final HidDevice device = devices.first;

print('Path: ${device.path}');
print('Vendor ID: 0x${device.vendorId.toRadixString(16)}');
print('Product ID: 0x${device.productId.toRadixString(16)}');
print('Serial Number: ${device.serialNumber}');
print('Manufacturer: ${device.manufacturer}');
print('Product Name: ${device.productName}');
print('Usage Page: 0x${device.usagePage.toRadixString(16)}');
print('Usage: 0x${device.usage.toRadixString(16)}');
print('Interface Number: ${device.interfaceNumber}');
print('Bus Type: ${device.busType}');
```

### Get Indexed String

```dart
final HidDevice device = ...;

try {
  await device.open();

  // Get a string from the device based on its string index
  String indexedString = await device.getIndexedString(1);

  print('Indexed string: $indexedString');

} finally {
  await device.close();
}
```

### Get HID Report Descriptor

```dart
final HidDevice device = ...;

try {
  await device.open();

  // Get the HID report descriptor from the device
  // This method is available since hidapi 0.14.0+
  HidReportDescriptor descriptor = await device.getReportDescriptor();

  // Access the raw bytes
  print('Raw descriptor: ${descriptor.rawBytes}');

  // Access parsed collections
  print('Collections: ${descriptor.collections.length}');
  for (var collection in descriptor.collections) {
    print('  Collection: UsagePage=0x${collection.usagePage.toRadixString(16)}, '
          'Usage=0x${collection.usage.toRadixString(16)}, '
          'Type=${collection.collectionType}');
    print('    Items: ${collection.items.length}');
    print('    Children: ${collection.children.length}');
  }

  // Access parsed input/output/feature items
  print('Input items: ${descriptor.inputs.length}');
  print('Output items: ${descriptor.outputs.length}');
  print('Feature items: ${descriptor.features.length}');

  // Example: iterate over all input items
  for (var input in descriptor.inputs) {
    print('  Input: ReportId=${input.reportId}, '
          'UsagePage=0x${input.usagePage.toRadixString(16)}, '
          'ReportSize=${input.reportSize}, '
          'ReportCount=${input.reportCount}');
  }

} finally {
  await device.close();
}
```

## API Reference

### HidDevice Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | String | Unique device identifier |
| `path` | String | Platform-specific device path |
| `vendorId` | int | Device Vendor ID (VID) |
| `productId` | int | Device Product ID (PID) |
| `serialNumber` | String | Device serial number |
| `releaseNumber` | int | Device release number (BCD) |
| `manufacturer` | String | Manufacturer string |
| `productName` | String | Product name string |
| `usagePage` | int | Usage page for this device |
| `usage` | int | Usage for this device |
| `interfaceNumber` | int | USB interface number |
| `busType` | int | Underlying bus type (USB, Bluetooth, etc.) |
| `isOpen` | bool | Whether the device is open |

### HidDevice Methods

| Method | Description |
|--------|-------------|
| `open()` | Open the HID device connection |
| `close()` | Close the HID device connection |
| `sendReport(data, reportId)` | Send an Output report |
| `sendOutputReport(data, reportId)` | Send an Output report via Interrupt OUT (hidapi 0.15.0+) |
| `receiveReport(length, timeout)` | Receive an Input report |
| `inputStream()` | Get a stream of input bytes |
| `sendFeatureReport(data, reportId)` | Send a Feature report |
| `receiveFeatureReport(reportId, bufferSize)` | Receive a Feature report |
| `getIndexedString(index, maxLength)` | Get a string by its index |
| `getReportDescriptor()` | Get and parse the HID report descriptor (hidapi 0.14.0+) |

### Report Descriptor Classes

| Class | Description |
|-------|-------------|
| `HidReportDescriptor` | Represents a parsed HID report descriptor |
| `HidCollection` | Represents a HID collection in the descriptor |
| `HidReportItem` | Represents a report item (Input/Output/Feature) |
| `HidReportType` | Enum for report type (input/output/feature) |

### HidReportDescriptor Properties

| Property | Type | Description |
|----------|------|-------------|
| `rawBytes` | Uint8List | The raw bytes of the report descriptor |
| `collections` | List<HidCollection> | Top-level collections in the descriptor |
| `inputs` | List<HidReportItem> | All input report items |
| `outputs` | List<HidReportItem> | All output report items |
| `features` | List<HidReportItem> | All feature report items |

### HidCollection Properties

| Property | Type | Description |
|----------|------|-------------|
| `usagePage` | int | The usage page of this collection |
| `usage` | int | The usage of this collection |
| `collectionType` | int | The type of collection (Physical, Application, Logical, etc.) |
| `children` | List<HidCollection> | Child collections (nested collections) |
| `items` | List<HidReportItem> | Report items directly in this collection |
| `parent` | HidCollection? | Parent collection (null for top-level collections) |

### HidReportItem Properties

| Property | Type | Description |
|----------|------|-------------|
| `reportType` | HidReportType | The type of report item (Input, Output, Feature) |
| `reportId` | int | The report ID (0 if not used) |
| `usagePage` | int | The usage page for this item |
| `usage` | int? | The usage for this item |
| `usageMinimum` | int? | The minimum usage (for ranges) |
| `usageMaximum` | int? | The maximum usage (for ranges) |
| `logicalMinimum` | int? | The logical minimum value |
| `logicalMaximum` | int? | The logical maximum value |
| `physicalMinimum` | int? | The physical minimum value |
| `physicalMaximum` | int? | The physical maximum value |
| `reportSize` | int | The size of each report field in bits |
| `reportCount` | int | The number of report fields |
| `unitExponent` | int? | The unit exponent |
| `unit` | int? | The unit |
| `isArray` | bool | Whether the item is an array |
| `isAbsolute` | bool | Whether the item uses absolute positioning |
| `hasNull` | bool | Whether null state is supported |
| `isVariable` | bool | Whether this item has variable size |
| `bitPosition` | int | Bit position in the report |

## Device Connection/Disconnection Events

The plugin provides a stream-based API for listening to HID device connection and disconnection events without polling.

### Example Usage

```dart
import 'package:hid_tool/hid_tool.dart';

// Start listening for device events
await Hid.startListening();

// Listen for device connected events
HidDeviceEvents.onConnected.listen((event) {
  print('Device connected: ${event.path}');
  print('  Vendor ID: 0x${event.vendorId?.toRadixString(16) ?? 'unknown'}');
  print('  Product ID: 0x${event.productId?.toRadixString(16) ?? 'unknown'}');
});

// Listen for device disconnected events
HidDeviceEvents.onDisconnected.listen((event) {
  print('Device disconnected: ${event.path}');
});

// Stop listening when no longer needed
await Hid.stopListening();
```

### HidDeviceEvent Properties

| Property | Type | Description |
|----------|------|-------------|
| `path` | String | The device path identifier |
| `vendorId` | int? | The vendor ID of the device |
| `productId` | int? | The product ID of the device |
| `timestamp` | DateTime | The timestamp of the event |

## Planned Features

These features are planned for future releases:

- **Android Support**: Add Android platform support using MethodChannel and Android HID API.
- **Web Support**: Add Web platform support using WebHID API.

## Error Handling

The plugin throws `HidException` when HID operations fail:

```dart
try {
  await device.open();
  await device.sendReport(data);
} on HidException catch (e) {
  print('HID Error: ${e.message}');
} on StateError catch (e) {
  print('State Error: ${e.message}');
}
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 中文

`hid_tool` 是一个 Flutter 插件，用于在 Flutter 应用程序中与 HID（人机接口设备）设备进行通信。

## 致谢

本项目是 [hid4flutter](https://github.com/vinsfortunato/hid4flutter) 的分支/修改版本，原作者为 vinsfortunato。我们将其重命名为 `hid_tool`，并升级了底层的 hidapi 库到 0.15.0 版本，同时添加了额外的方法和改进。

原项目地址：[https://github.com/vinsfortunato/hid4flutter](https://github.com/vinsfortunato/hid4flutter)

## 免责声明

**警告：** 此插件目前处于开发阶段，API 可能会发生变化。在生产环境中使用风险自担。

欢迎贡献！请随时提交 issue 和 pull request 来帮助改进此插件。

## 支持的平台

- ✅ Windows
- ✅ macOS
- ✅ Linux（需要手动安装 `libhidapi-hidraw0`，参见 [安装](#安装)）

### 实现细节

桌面平台（Windows/macOS/Linux）支持通过使用 [hidapi](https://github.com/libusb/hidapi)（版本 0.15.0）和 Dart FFI 实现。

### 计划支持的平台

计划在不久的将来添加以下平台的支持：

- **Android**：可以使用 MethodChannel 和 Android HID API 支持。
- **Web**：可以使用实验性的 WebHID API 支持 Web 平台。

## 安装

### 步骤 1：添加依赖

将以下行添加到您的 `pubspec.yaml` 文件中：

```yaml
dependencies:
  hid_tool: ^0.0.7
```

将 `^0.0.1` 替换为插件的最新版本。

### 步骤 2：安装依赖

运行以下命令以安装依赖：

```bash
flutter pub get
```

### 步骤 3：导入包

在您的 Dart 代码中导入 `hid_tool` 包：

```dart
import 'package:hid_tool/hid_tool.dart';
```

### 平台特定说明

#### Linux

在 Linux 上，您需要手动安装 `hidapi`：

```bash
sudo apt-get install libhidapi-hidraw0
```

#### macOS

在 macOS 上，hidapi 依赖由 CocoaPods 自动管理。

#### Windows

在 Windows 上，hidapi 作为构建过程的一部分自动编译。

## 示例应用

完整的示例应用可在 [`example/`](example/) 目录中找到。示例展示了：

- **设备枚举** - 列出所有连接的 HID 设备
- **事件监听** - 实时的设备连接/断开事件
- **报告描述符解析** - 获取并显示设备报告描述符
- **设备详情视图** - 查看全面的设备信息

### 运行示例

```bash
cd example
flutter pub get
flutter run
```

详细文档请参见 [example/README.md](example/README.md)。

## 使用方法

### 初始化和获取设备

```dart
import 'package:hid_tool/hid_tool.dart';

// 获取所有连接的 HID 设备
List<HidDevice> devices = await Hid.getDevices();

// 按供应商 ID 和产品 ID 获取设备
List<HidDevice> filteredDevices = await Hid.getDevices(
  vendorId: 0x046D,
  productId: 0xC52B,
);

// 按使用页和使用获取设备
List<HidDevice> usageFilteredDevices = await Hid.getDevices(
  usagePage: 0xFF00,
  usage: 0x01,
);
```

### 打开和关闭设备

```dart
final HidDevice device = devices.first;

try {
  // 打开设备连接
  await device.open();

  // 检查设备是否已打开
  if (device.isOpen) {
    print('设备已打开');
  }

  // ... 执行操作 ...

} finally {
  // 完成后始终关闭设备
  await device.close();
}
```

### 发送输出报告

```dart
final HidDevice device = ...;

try {
  await device.open();

  // 发送 32 字节的输出报告（全零）
  // reportId 是可选的（默认为 0x00）
  // 它将根据 HID 规则添加到数据前面
  Uint8List data = Uint8List(32);
  await device.sendReport(data, reportId: 0x00);

} finally {
  await device.close();
}
```

### 发送输出报告（使用 hidapi 0.15.0+ 方法）

```dart
final HidDevice device = ...;

try {
  await device.open();

  // 使用新的 sendOutputReport 方法（hidapi 0.15.0+）
  // 如果可用，这将通过中断 OUT 端点发送
  Uint8List data = Uint8List(32);
  await device.sendOutputReport(data, reportId: 0x00);

} finally {
  await device.close();
}
```

### 接收输入报告

```dart
final HidDevice device = ...;

try {
  await device.open();

  // 接收 32 字节的报告，超时时间为 2 秒
  Uint8List data = await device.receiveReport(32, timeout: const Duration(seconds: 2));

  // 第一个字节始终是报告 ID
  int reportId = data[0];

  print('收到报告 ID $reportId: $data');

} finally {
  await device.close();
}
```

### 监听输入流

```dart
final HidDevice device = ...;

try {
  await device.open();

  // 监听来自设备的输入流
  device.inputStream().listen((byte) {
    print('收到字节：$byte');
  });

} finally {
  await device.close();
}
```

### 发送功能报告

```dart
final HidDevice device = ...;

try {
  await device.open();

  // 发送功能报告
  Uint8List data = Uint8List(16);
  await device.sendFeatureReport(data, reportId: 0x01);

} finally {
  await device.close();
}
```

### 接收功能报告

```dart
final HidDevice device = ...;

try {
  await device.open();

  // 接收功能报告
  Uint8List data = await device.receiveFeatureReport(0x01, bufferSize: 64);

  print('功能报告：$data');

} finally {
  await device.close();
}
```

### 获取设备信息

```dart
final HidDevice device = devices.first;

print('路径：${device.path}');
print('供应商 ID: 0x${device.vendorId.toRadixString(16)}');
print('产品 ID: 0x${device.productId.toRadixString(16)}');
print('序列号：${device.serialNumber}');
print('制造商：${device.manufacturer}');
print('产品名称：${device.productName}');
print('使用页：0x${device.usagePage.toRadixString(16)}');
print('使用：0x${device.usage.toRadixString(16)}');
print('接口号：${device.interfaceNumber}');
print('总线类型：${device.busType}');
```

### 获取索引字符串

```dart
final HidDevice device = ...;

try {
  await device.open();

  // 根据字符串索引从设备获取字符串
  String indexedString = await device.getIndexedString(1);

  print('索引字符串：$indexedString');

} finally {
  await device.close();
}
```

### 获取 HID 报告描述符

```dart
final HidDevice device = ...;

try {
  await device.open();

  // 从设备获取 HID 报告描述符
  // 此方法在 hidapi 0.14.0+ 版本可用
  HidReportDescriptor descriptor = await device.getReportDescriptor();

  // 访问原始字节
  print('原始描述符：${descriptor.rawBytes}');

  // 访问解析后的集合
  print('集合数：${descriptor.collections.length}');
  for (var collection in descriptor.collections) {
    print('  集合：UsagePage=0x${collection.usagePage.toRadixString(16)}, '
          'Usage=0x${collection.usage.toRadixString(16)}, '
          '类型=${collection.collectionType}');
    print('    项数：${collection.items.length}');
    print('    子集合数：${collection.children.length}');
  }

  // 访问解析后的输入/输出/功能项
  print('输入项数：${descriptor.inputs.length}');
  print('输出项数：${descriptor.outputs.length}');
  print('功能项数：${descriptor.features.length}');

  // 示例：遍历所有输入项
  for (var input in descriptor.inputs) {
    print('  输入：ReportId=${input.reportId}, '
          'UsagePage=0x${input.usagePage.toRadixString(16)}, '
          'ReportSize=${input.reportSize}, '
          'ReportCount=${input.reportCount}');
  }

} finally {
  await device.close();
}
```

## API 参考

### HidDevice 属性

| 属性 | 类型 | 描述 |
|------|------|------|
| `id` | String | 唯一设备标识符 |
| `path` | String | 平台特定的设备路径 |
| `vendorId` | int | 设备供应商 ID (VID) |
| `productId` | int | 设备产品 ID (PID) |
| `serialNumber` | String | 设备序列号 |
| `releaseNumber` | int | 设备版本号（BCD 编码） |
| `manufacturer` | String | 制造商字符串 |
| `productName` | String | 产品名称字符串 |
| `usagePage` | int | 设备使用页 |
| `usage` | int | 设备使用 |
| `interfaceNumber` | int | USB 接口号 |
| `busType` | int | 底层总线类型（USB、蓝牙等） |
| `isOpen` | bool | 设备是否已打开 |

### HidDevice 方法

| 方法 | 描述 |
|------|------|
| `open()` | 打开 HID 设备连接 |
| `close()` | 关闭 HID 设备连接 |
| `sendReport(data, reportId)` | 发送输出报告 |
| `sendOutputReport(data, reportId)` | 通过中断 OUT 发送输出报告（hidapi 0.15.0+） |
| `receiveReport(length, timeout)` | 接收输入报告 |
| `inputStream()` | 获取输入字节流 |
| `sendFeatureReport(data, reportId)` | 发送功能报告 |
| `receiveFeatureReport(reportId, bufferSize)` | 接收功能报告 |
| `getIndexedString(index, maxLength)` | 按索引获取字符串 |
| `getReportDescriptor()` | 获取并解析 HID 报告描述符（hidapi 0.14.0+） |

### 报告描述符类

| 类 | 描述 |
|------|------|
| `HidReportDescriptor` | 表示解析后的 HID 报告描述符 |
| `HidCollection` | 表示描述符中的 HID 集合 |
| `HidReportItem` | 表示报告项（输入/输出/功能） |
| `HidReportType` | 报告类型枚举（输入/输出/功能） |

### HidReportDescriptor 属性

| 属性 | 类型 | 描述 |
|------|------|------|
| `rawBytes` | Uint8List | 报告描述符的原始字节 |
| `collections` | List<HidCollection> | 描述符中的顶层集合 |
| `inputs` | List<HidReportItem> | 所有输入报告项 |
| `outputs` | List<HidReportItem> | 所有输出报告项 |
| `features` | List<HidReportItem> | 所有功能报告项 |

### HidCollection 属性

| 属性 | 类型 | 描述 |
|------|------|------|
| `usagePage` | int | 集合的使用页 |
| `usage` | int | 集合的使用 |
| `collectionType` | int | 集合类型（物理、应用、逻辑等） |
| `children` | List<HidCollection> | 子集合（嵌套集合） |
| `items` | List<HidReportItem> | 此集合中的报告项 |
| `parent` | HidCollection? | 父集合（顶层集合为 null） |

### HidReportItem 属性

| 属性 | 类型 | 描述 |
|------|------|------|
| `reportType` | HidReportType | 报告项类型（输入、输出、功能） |
| `reportId` | int | 报告 ID（未使用时为 0） |
| `usagePage` | int | 项的使用页 |
| `usage` | int? | 项的使用 |
| `usageMinimum` | int? | 最小使用值（范围） |
| `usageMaximum` | int? | 最大使用值（范围） |
| `logicalMinimum` | int? | 逻辑最小值 |
| `logicalMaximum` | int? | 逻辑最大值 |
| `physicalMinimum` | int? | 物理最小值 |
| `physicalMaximum` | int? | 物理最大值 |
| `reportSize` | int | 每个报告字段的位数 |
| `reportCount` | int | 报告字段数量 |
| `unitExponent` | int? | 单位指数 |
| `unit` | int? | 单位 |
| `isArray` | bool | 是否为数组 |
| `isAbsolute` | bool | 是否使用绝对定位 |
| `hasNull` | bool | 是否支持 null 状态 |
| `isVariable` | bool | 是否为变量大小 |
| `bitPosition` | int | 报告中的位位置 |

## 设备连接/断开事件

插件提供基于流的 API 来监听 HID 设备连接和断开事件，无需轮询。

### 使用示例

```dart
import 'package:hid_tool/hid_tool.dart';

// 开始监听设备事件
await Hid.startListening();

// 监听设备连接事件
HidDeviceEvents.onConnected.listen((event) {
  print('设备已连接：${event.path}');
  print('  供应商 ID: 0x${event.vendorId?.toRadixString(16) ?? 'unknown'}');
  print('  产品 ID: 0x${event.productId?.toRadixString(16) ?? 'unknown'}');
});

// 监听设备断开事件
HidDeviceEvents.onDisconnected.listen((event) {
  print('设备已断开：${event.path}');
});

// 不再需要时停止监听
await Hid.stopListening();
```

### HidDeviceEvent 属性

| 属性 | 类型 | 描述 |
|------|------|------|
| `path` | String | 设备路径标识符 |
| `vendorId` | int? | 设备的供应商 ID |
| `productId` | int? | 设备的产品 ID |
| `timestamp` | DateTime | 事件时间戳 |

## 计划功能

这些功能计划在将来的版本中添加：

- **Android 支持**：使用 MethodChannel 和 Android HID API 添加 Android 平台支持。
- **Web 支持**：使用 WebHID API 添加 Web 平台支持。

## 错误处理

当 HID 操作失败时，插件会抛出 `HidException`：

```dart
try {
  await device.open();
  await device.sendReport(data);
} on HidException catch (e) {
  print('HID 错误：${e.message}');
} on StateError catch (e) {
  print('状态错误：${e.message}');
}
```

## 许可证

本项目根据 MIT 许可证授权 - 有关详细信息，请参阅 [LICENSE](LICENSE) 文件。
