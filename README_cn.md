# hid_tool

[![pub](https://img.shields.io/badge/pub-0.0.9-blue)](https://pub.dev/packages/hid_tool)
[![license: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)

[English](README.md) | 中文

---

## 目录

- [概述](#概述)
- [致谢](#致谢)
- [免责声明](#免责声明)
- [支持的平台](#支持的平台)
- [安装](#安装)
- [示例应用](#示例应用)
- [使用方法](#使用方法)
- [API 参考](#api-参考)
- [设备连接/断开事件](#设备连接断开事件)
- [后续计划](#后续计划)
- [错误处理](#错误处理)
- [已知问题和限制](#已知问题和限制)
- [贡献](#贡献)
- [许可证](#许可证)

---

## 概述

`hid_tool` 是一个 Flutter 插件，用于在 Flutter 应用程序中与 HID（人机接口设备）设备进行通信。

此插件提供了全面的 API，用于在当前已支持的 Flutter 平台上与 HID 设备交互：

- **设备枚举** - 列出所有连接的 HID 设备及其详细信息
- **设备通信** - 发送和接收输入/输出/功能报告
- **报告描述符解析** - 获取并解析 HID 报告描述符为结构化数据
- **事件监听** - 实时的设备连接/断开通知
- **输入流** - 基于流的 API 用于连续数据接收

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
- ✅ Android

### 实现细节

- 桌面平台（Windows/macOS/Linux）通过 [hidapi](https://github.com/libusb/hidapi)（版本 0.15.0）和 Dart FFI 实现。
- Android 平台通过 MethodChannel 和 Android USB HID API 实现。

### 当前暂不支持

- iOS
- Web

## 安装

### 步骤 1：添加依赖

将以下行添加到您的 `pubspec.yaml` 文件中：

```yaml
dependencies:
  hid_tool: ^0.0.9
```

将 `^0.0.9` 替换为插件的最新版本。

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

## 后续计划

这些功能计划在将来的版本中添加：

- **iOS 支持**：添加 iOS 平台支持。
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

## 已知问题和限制

### 当前实现说明

1. **发送报告响应处理**：使用 `sendReport()`、`sendOutputReport()` 或 `sendFeatureReport()` 时，如果发送的字节数与预期的缓冲区长度不同，当前实现未处理此情况。源代码中已用 TODO 注释标记，供未来改进。

2. **输入流轮询**：`inputStream()` 方法使用 100 微秒间隔的轮询。在未来的版本中可能会进行调整以提高性能或电源效率。

3. **部分写入的错误处理**：发送报告时，如果发生部分写入（result != buffer.length），当前行为未定义，可能会在未来的版本中改进。

### 平台特定限制

- **Linux**：设备事件监听需要正确的 udev 权限。某些发行版可能需要额外的配置。
- **macOS**：最低部署目标是 macOS 10.13，这是由于 Xcode 兼容性要求。
- **Windows**：某些设备的 HID 设备访问可能需要管理员权限。

## 贡献

欢迎贡献！您可以通过以下方式提供帮助：

- **报告错误**：在 [GitHub 仓库](https://github.com/ArdWang/hid_tool/issues) 上提交问题，并详细描述问题。
- **建议功能**：在实施之前，打开一个问题来讨论新功能想法。
- **提交 Pull Request**：Fork 仓库，进行更改，然后提交 pull request。请确保您的代码遵循现有的代码风格，并包含适当的测试。
- **改进文档**：通过修复错别字、添加示例或澄清解释来帮助改进文档。

## 许可证

本项目根据 MIT 许可证授权 - 有关详细信息，请参阅 [LICENSE](LICENSE) 文件。
