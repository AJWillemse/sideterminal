// swift-tools-version: 5.10
import PackageDescription

// SideTerminalCore holds the app's pure, platform-independent logic —
// shortcut parsing, path validation, terminal-config rendering. It has no
// dependency on the engine library or on bleeding-edge macOS SDK APIs, so it
// builds and its tests run on any recent macOS (including CI runners), while
// the full app requires the macOS 26 SDK.
let package = Package(
    name: "SideTerminalCore",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "SideTerminalCore", targets: ["SideTerminalCore"]),
    ],
    targets: [
        .target(name: "SideTerminalCore"),
        .testTarget(
            name: "SideTerminalCoreTests",
            dependencies: ["SideTerminalCore"]
        ),
    ]
)
