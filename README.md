# hid_tool

[![pub](https://img.shields.io/badge/pub-0.0.1-blue)](https://pub.dev/packages/hid_tool)
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
  hid_tool: ^0.0.1
```

Replace `^0.0.1` with the latest version of the plugin.

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

## Planned Features

These features are planned for future releases:

- **Get Device HID Report Descriptor**: Request the report descriptor from the device and return it as a structured object representing the HID collections.
- **Device Connection/Disconnection Events**: Add the ability to listen for device connection/disconnection events to avoid polling `getDevices()` function.

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
  hid_tool: ^0.0.1
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

## 计划功能

这些功能计划在将来的版本中添加：

- **获取设备 HID 报告描述符**：从设备请求报告描述符，并将其作为表示 HID 集合的结构化对象返回。
- **设备连接/断开事件**：添加监听设备连接/断开事件的能力，以避免轮询 `getDevices()` 函数。

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
