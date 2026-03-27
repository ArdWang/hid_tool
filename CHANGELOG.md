# Changelog

All notable changes to this project will be documented in this file.

## Acknowledgements / 致谢

This project is a fork/modified version of [hid4flutter](https://github.com/vinsfortunato/hid4flutter) by vinsfortunato.

本项目是 [hid4flutter](https://github.com/vinsfortunato/hid4flutter) 的分支/修改版本，原作者为 vinsfortunato。

---

## [0.0.3] - 2026-03-27
- Fix CMake configuration to properly link hidapi on MacOS.
- 修复 CMake 配置以正确连接 MacOS 上的 hidapi

## [0.0.2] - 2026-03-27

- Fix CMake configuration to properly link hidapi on Windows.
- 修复 CMake 配置以正确连接 Windows上的 hidapi

## [0.0.1] - 2026-03-26

### Added (新增)

- Added `sendOutputReport` method using hidapi 0.15.0's new `hid_send_output_report()` function.
  - 添加了 `sendOutputReport` 方法，使用 hidapi 0.15.0 的新 `hid_send_output_report()` 函数
- Added `hid_read_error()` function binding for better error handling.
  - 添加了 `hid_read_error()` 函数绑定以提供更好的错误处理
- Initial release of `hid_tool` (renamed from `hid4flutter`).
  - `hid_tool` 首次发布（从 `hid4flutter` 重命名）

### Changed (更改)

- Upgraded hidapi to version 0.15.0.
  - 升级 hidapi 到版本 0.15.0
- Renamed package from `hid4flutter` to `hid_tool`.
  - 将包名从 `hid4flutter` 重命名为 `hid_tool`
- Updated all platform implementations to use new naming convention.
  - 更新了所有平台实现以使用新的命名约定
- Updated CMake configuration to use modern version syntax.
  - 更新 CMake 配置以使用现代版本语法

---

## [0.1.3] - 2026-03-26 (Unreleased/未发布)

### Added (新增)

- Added `sendOutputReport` method using hidapi 0.15.0's new `hid_send_output_report()` function.
  - 添加了 `sendOutputReport` 方法，使用 hidapi 0.15.0 的新 `hid_send_output_report()` 函数
- Added `hid_read_error()` function binding for better error handling.
  - 添加了 `hid_read_error()` 函数绑定以提供更好的错误处理

### Changed (更改)

- Upgraded hidapi to version 0.15.0.
  - 升级 hidapi 到版本 0.15.0
- Renamed package from `hid4flutter` to `hid_tool`.
  - 将包名从 `hid4flutter` 重命名为 `hid_tool`

---

## [0.1.2] - 2026-03-26

### Fixed (修复)

- Remove CMake warning when building on Windows.
  - 修复在 Windows 上构建时的 CMake 警告

### Changed (更改)

- Use git submodule to download hidapi sources on Windows.
  - 在 Windows 上使用 git 子模块下载 hidapi 源代码
- Improve code quality.
  - 改进代码质量

---

## [0.1.1]

### Fixed (修复)

- Fix macOS podspec summary and description.
  - 修复 macOS podspec 的摘要和描述
- Fix test to clear pub publish warnings.
  - 修复测试以清除 pub 发布警告

---

## [0.1.0]

### Added (新增)

- Support for macOS platform.
  - 支持 macOS 平台
- Support for Linux platform.
  - 支持 Linux 平台
- Add filters to `Hid.getDevices(...)` method.
  - 为 `Hid.getDevices(...)` 方法添加过滤器
- Add a working flutter example application in /example/
  - 在 /example/ 中添加可用的 Flutter 示例应用程序
- Add `inputStream()` method to `HidDevice` to get a stream of bytes received from the device as part of an input report.
  - 为 `HidDevice` 添加 `inputStream()` 方法以获取作为输入报告一部分从设备接收的字节流

### Changed (更改)

- Upgrade used hidapi version to `0.14.0`.
  - 升级使用的 hidapi 版本到 `0.14.0`
- Remove `Hid.init()` and `Hid.exit()` methods. Resources are now freed automatically when all devices get closed.
  - 移除 `Hid.init()` 和 `Hid.exit()` 方法。资源现在会在所有设备关闭时自动释放
- Change property `product` to `productName` in `HidDevice` class.
  - 将 `HidDevice` 类中的 `product` 属性更改为 `productName`
- Improve API naming and usage.
  - 改进 API 命名和用法
- Improve documentation.
  - 改进文档
- Remove android from apparently supported platforms in pubspec since it is still not supported.
  - 从 pubspec 中移除 Android（因为尚未支持）

### Fixed (修复)

- Compile hidapi on windows instead of bundling pre-compiled dylibs.
  - 在 Windows 上编译 hidapi 而不是捆绑预编译的 dylibs
- Remove unused/unnecessary native code.
  - 移除未使用/不必要的原生代码
- Fix pointer of Char/WChar to String conversions.
  - 修复 Char/WChar 指针到 String 的转换
- Fix input report receiving implementation on desktop platforms.
  - 修复桌面平台上的输入报告接收实现

---

## [0.0.1]

### Added (新增)

- Initial release.
  - 首次发布

**Note:** As of now, `hid4flutter` is only supported on Windows. Support for other platforms will be added in future releases.

**注意：** 截至目前，`hid4flutter` 仅支持 Windows。其他平台的支持将在未来的版本中添加。
