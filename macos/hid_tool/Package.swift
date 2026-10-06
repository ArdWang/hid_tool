// swift-tools-version: 5.9
//
// Swift Package Manager manifest for the hid_tool macOS plugin.
//
// Keeping this file (alongside macos/hid_tool.podspec) means the plugin is
// usable by applications that have migrated to Swift Package Manager as well as
// by applications that still use CocoaPods.
//
import PackageDescription

let package = Package(
    name: "hid_tool",
    platforms: [
        .macOS("10.13")
    ],
    products: [
        // The library name must be hyphen separated because Swift Package
        // Manager uses it as the CFBundleIdentifier when linked dynamically.
        .library(name: "hid-tool", targets: ["hid_tool"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        // hidapi is vendored in the repository (third_party/hidapi) and is also
        // consumed there by the Windows and Linux CMake builds.
        .package(name: "hidapi", path: "../../third_party/hidapi")
    ],
    targets: [
        .target(
            name: "hid_tool",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "hidapi", package: "hidapi")
            ]
        )
    ]
)
