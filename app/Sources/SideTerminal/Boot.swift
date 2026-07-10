import AppKit
import GhosttyKit

@main
@MainActor
struct SideTerminalApp {
    static func main() {
        setupResourcesDir()

        // Initialize Ghostty global state before anything touches libghostty.
        guard ghostty_init(UInt(CommandLine.argc), CommandLine.unsafeArgv) == GHOSTTY_SUCCESS else {
            FileHandle.standardError.write(Data("ghostty_init failed\n".utf8))
            exit(1)
        }

        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    /// Locate the Ghostty resources (terminfo, shell integration, themes)
    /// inside the app bundle before libghostty initializes. Falls back to the
    /// build tree during development so `swift run` works.
    private static func setupResourcesDir() {
        if ProcessInfo.processInfo.environment["GHOSTTY_RESOURCES_DIR"] != nil { return }

        let candidates: [URL?] = [
            Bundle.main.resourceURL?.appendingPathComponent("ghostty"),
            Bundle.main.executableURL?
                .deletingLastPathComponent()
                .appendingPathComponent("../../../ghostty/zig-out/share/ghostty"),
        ]

        for candidate in candidates {
            guard let url = candidate?.standardizedFileURL else { continue }
            if FileManager.default.fileExists(atPath: url.path) {
                setenv("GHOSTTY_RESOURCES_DIR", url.path, 1)
                return
            }
        }
    }
}
