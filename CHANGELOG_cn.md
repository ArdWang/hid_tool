# 更新日志

本项目的所有重要更改都将记录在此文件中。

## 致谢

本项目是 [hid4flutter](https://github.com/vinsfortunato/hid4flutter) 的分支/修改版本，原作者为 vinsfortunato。

---

## [0.0.8] - 2026-04-03

### 更改

- 将文档分离为英文（README.md, CHANGELOG.md）和中文（README_cn.md, CHANGELOG_cn.md）文件
- 在 README.md 中添加贡献指南
- 更新文档中的版本号为 0.0.8

### 优化

- **extensions.dart**: 使用 `ffi` 包内置的 `Utf8` 和 `Utf16` 方法替换自定义指针转字符串转换，提高效率
- **hid_report_descriptor_parser.dart**: 移除了 size type 处理的重复代码（从 8 行简化为 1 行）
- **hid_device_desktop.dart**: 
  - 将 TODO 注释更改为描述性说明，解释部分写入的预期行为
  - 将输入流轮询间隔从 100 微秒增加到 1 毫秒，提高电源效率
  - 移除了 `inputStream()` 方法中不必要的变量初始化

---

## [0.0.7] - 2026-03-30

### 修复

- 通过手动定义常量修复了 macOS 构建错误 "cannot find 'kIOHIDDevicePathKey' in scope'"
- 在 Swift 文件中添加了 `kIOHIDDevicePathKey` 常量声明，因为无法直接导入 IOKit 子模块

---

## [0.0.6] - 2026-03-30

### 修复

- 修复 macOS 构建错误 "no such module 'IOKit.hid.IOHIDLib'"，移除了无效的导入语句
- 在 macOS podspec 中添加了 `IOKit` 框架以正确链接
- 更新 macOS 最低部署目标到 10.13（Xcode 兼容版本）
- 修复了 Windows 编译错误：
  - `GUID_DEVINTERFACE_HID` 重定义错误
  - MethodChannel `InvokeMethod` 类型不匹配
- 添加 `.claude/` 到 `.gitignore` 防止 Claude Code 设置被提交

### 更改

- 更新了所有平台实现以确保一致的构建体验

---

## [0.0.5] - 2026-03-30

### 新增

- 添加了 `.claude/` 目录的 `.gitignore` 条目

### 更改

- 改进了 macOS 设备事件监听实现
- 更新设备事件监听仅在显式调用时启动

---

## [0.0.4] - 2026-03-30

### 新增

- 添加了 `getReportDescriptor()` 方法以从设备获取并解析 HID 报告描述符（需要 hidapi 0.14.0+）
- 添加了 `HidReportDescriptor` 类以表示解析后的报告描述符，包含集合和报告项
- 添加了 `HidCollection` 类以表示 HID 集合，支持嵌套结构
- 添加了 `HidReportItem` 类以表示输入/输出/功能报告项，包含完整的描述符信息
- 添加了 `HidReportType` 枚举用于报告类型识别
- 添加了 `HidReportDescriptorParser` 类以将原始描述符字节解析为结构化对象
- 添加了 `HidDeviceEvents` 类用于在 Windows、macOS 和 Linux 上监听设备连接/断开事件
- 添加了 `HidDeviceEvent` 类以表示设备连接/断开事件，包含路径、供应商 ID 和产品 ID
- 添加了 `Hid.startListening()` 和 `Hid.stopListening()` 方法用于管理设备事件监听器
- 使用 `RegisterDeviceNotification` API 实现了 Windows 平台设备通知
- 使用 IOKit 框架实现了 macOS 平台设备通知
- 使用 udev/netlink 实现了 Linux 平台设备通知

### 更改

- 更新了 README.md，添加了新报告描述符 API 的文档和示例
- 更新了 README.md，添加了设备事件监听 API 的文档和示例

---

## [0.0.3] - 2026-03-27

- 修复 CMake 配置以正确连接 MacOS 上的 hidapi

## [0.0.2] - 2026-03-27

- 修复 CMake 配置以正确连接 Windows 上的 hidapi

## [0.0.1] - 2026-03-26

### 新增

- 添加了 `sendOutputReport` 方法，使用 hidapi 0.15.0 的新 `hid_send_output_report()` 函数
- 添加了 `hid_read_error()` 函数绑定以提供更好的错误处理
- `hid_tool` 首次发布（从 `hid4flutter` 重命名）

### 更改

- 升级 hidapi 到版本 0.15.0
- 将包名从 `hid4flutter` 重命名为 `hid_tool`
- 更新了所有平台实现以使用新的命名约定
- 更新 CMake 配置以使用现代版本语法

---

## [0.1.3] - 2026-03-26 (未发布)

### 新增

- 添加了 `sendOutputReport` 方法，使用 hidapi 0.15.0 的新 `hid_send_output_report()` 函数
- 添加了 `hid_read_error()` 函数绑定以提供更好的错误处理

### 更改

- 升级 hidapi 到版本 0.15.0
- 将包名从 `hid4flutter` 重命名为 `hid_tool`

---

## [0.1.2] - 2026-03-26

### 修复

- 修复在 Windows 上构建时的 CMake 警告

### 更改

- 在 Windows 上使用 git 子模块下载 hidapi 源代码
- 改进代码质量

---

## [0.1.1]

### 修复

- 修复 macOS podspec 的摘要和描述
- 修复测试以清除 pub 发布警告

---

## [0.1.0]

### 新增

- 支持 macOS 平台
- 支持 Linux 平台
- 为 `Hid.getDevices(...)` 方法添加过滤器
- 在 /example/ 中添加可用的 Flutter 示例应用程序
- 为 `HidDevice` 添加 `inputStream()` 方法以获取作为输入报告一部分从设备接收的字节流

### 更改

- 升级使用的 hidapi 版本到 `0.14.0`
- 移除 `Hid.init()` 和 `Hid.exit()` 方法。资源现在会在所有设备关闭时自动释放
- 将 `HidDevice` 类中的 `product` 属性更改为 `productName`
- 改进 API 命名和用法
- 改进文档
- 从 pubspec 中移除 Android（因为尚未支持）

### 修复

- 在 Windows 上编译 hidapi 而不是捆绑预编译的 dylibs
- 移除未使用/不必要的原生代码
- 修复 Char/WChar 指针到 String 的转换
- 修复桌面平台上的输入报告接收实现

---

## [0.0.1]

### 新增

- 首次发布

**注意：** 截至目前，`hid4flutter` 仅支持 Windows。其他平台的支持将在未来的版本中添加。
