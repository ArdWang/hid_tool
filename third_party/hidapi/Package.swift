// swift-tools-version: 5.9
//
// Swift Package Manager manifest for the vendored hidapi sources.
//
// The macOS plugin (see macos/hid_tool/Package.swift) depends on this local
// package so that hidapi is built and linked without CocoaPods.
//
// Only the macOS back-end is described here; the Windows and Linux builds keep
// consuming this same source tree through CMake (see windows/CMakeLists.txt and
// linux/CMakeLists.txt).
//
import PackageDescription

let package = Package(
    name: "hidapi",
    platforms: [
        .macOS("10.13")
    ],
    products: [
        // A dynamic library is required: the Dart side resolves the hidapi
        // symbols from the running process (DynamicLibrary.executable()), so
        // the symbols must be present in a loaded image even though no native
        // code references them directly.
        .library(name: "hidapi", type: .dynamic, targets: ["hidapi"])
    ],
    targets: [
        .target(
            name: "hidapi",
            path: "mac",
            exclude: [
                "CMakeLists.txt",
                "Makefile-manual",
                "Makefile.am"
            ],
            sources: ["hid.c"],
            publicHeadersPath: ".",
            cSettings: [
                // hidapi_darwin.h includes "hidapi.h", which lives in hidapi/.
                .headerSearchPath("../hidapi")
            ],
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("CoreFoundation")
            ]
        )
    ]
)
