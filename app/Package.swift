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
        // Auto-updates. Its own EdDSA update-signing is separate from Apple
        // code signing/notarization, so it works for an unsigned/ad-hoc app.
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.4"),
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
                .product(name: "Sparkle", package: "Sparkle"),
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
                    // SwiftPM doesn't add this rpath automatically (Xcode's
                    // "Embed & Sign" build phase normally does). Without it,
                    // dyld can't resolve @rpath/Sparkle.framework once
                    // bundle-app.sh copies the framework into Contents/Frameworks.
                    "-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks",
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
