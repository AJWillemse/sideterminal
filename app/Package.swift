// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SideTerminal",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        // Pure, testable logic lives in its own package so its tests run on
        // any recent macOS; the app itself needs the macOS 26 SDK.
        .package(path: "Core"),
    ],
    targets: [
        .systemLibrary(
            name: "GhosttyKit",
            path: "Sources/GhosttyKit"
        ),
        .target(
            name: "GhosttyObjC",
            path: "Sources/GhosttyObjC",
            publicHeadersPath: "include"
        ),
        .executableTarget(
            name: "SideTerminal",
            dependencies: [
                "GhosttyKit",
                "GhosttyObjC",
                .product(name: "SideTerminalCore", package: "Core"),
            ],
            path: "Sources/SideTerminal",
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals"),
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-L../ghostty/zig-out/lib",
                    "-lghostty",
                    "-lc++",
                ]),
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit"),
                .linkedFramework("CoreText"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("CoreVideo"),
                .linkedFramework("QuartzCore"),
                .linkedFramework("Carbon"),
                .linkedFramework("UniformTypeIdentifiers"),
                .linkedFramework("UserNotifications"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("IOSurface"),
            ]
        ),
    ]
)
