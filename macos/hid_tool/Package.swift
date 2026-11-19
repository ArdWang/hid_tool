// swift-tools-version: 5.9
//
// Swift Package Manager manifest for the hid_tool macOS plugin.
//
import PackageDescription

let package = Package(
  name: "hid_tool",
  platforms: [
    .macOS("10.13")
  ],
  products: [
    .library(name: "hid-tool", targets: ["hid_tool"]),
    .library(name: "hidapi", type: .dynamic, targets: ["hidapi"]),
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework")
  ],
  targets: [
    .target(
      name: "hidapi",
      path: "hidapi",
      exclude: [
        "CMakeLists.txt",
        "Makefile-manual",
        "Makefile.am",
      ],
      sources: ["hid.c"],
      publicHeadersPath: ".",
      cSettings: [
        .headerSearchPath("../hidapi")
      ],
      linkerSettings: [
        .linkedFramework("IOKit"),
        .linkedFramework("CoreFoundation"),
      ]
    ),
    .target(
      name: "hid_tool",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework"),
        "hidapi",
      ]
    ),
  ]
)
