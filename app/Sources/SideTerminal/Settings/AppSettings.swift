import AppKit
import Combine
import ServiceManagement
import SideTerminalCore

/// Which screen edge the sidebar docks to.
enum SidebarEdge: String, CaseIterable, Identifiable {
    case left
    case right

    var id: String { rawValue }
    var label: String {
        switch self {
        case .left: return "Left"
        case .right: return "Right"
        }
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return "Follow System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var appearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }
}

enum TerminalCursorStyle: String, CaseIterable, Identifiable {
    case block
    case bar
    case underline

    var id: String { rawValue }
    var label: String {
        switch self {
        case .block: return "Block"
        case .bar: return "Bar"
        case .underline: return "Underline"
        }
    }
}

/// How fast reveal/hide animations play. Scales the base spring timing.
enum AnimationSpeed: String, CaseIterable, Identifiable {
    case relaxed
    case balanced
    case brisk

    var id: String { rawValue }
    var label: String {
        switch self {
        case .relaxed: return "Relaxed"
        case .balanced: return "Balanced"
        case .brisk: return "Brisk"
        }
    }

    /// Multiplier applied to animation durations.
    var multiplier: Double {
        switch self {
        case .relaxed: return 1.3
        case .balanced: return 1.0
        case .brisk: return 0.75
        }
    }
}

/// Central, observable application settings backed by UserDefaults.
/// Every mutation publishes so UI and the sidebar react live.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    // MARK: General

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: "general.launchAtLogin")
            applyLaunchAtLogin()
        }
    }

    @Published var showMenuBarIcon: Bool {
        didSet { defaults.set(showMenuBarIcon, forKey: "general.showMenuBarIcon") }
    }

    /// Whether the app appears in the Dock (and the ⌘⇥ switcher).
    @Published var showInDock: Bool {
        didSet { defaults.set(showInDock, forKey: "general.showInDock") }
    }

    /// Global shortcut to toggle the sidebar, encoded as "modifiers+key",
    /// e.g. "cmd+shift+t". Empty disables it.
    @Published var globalShortcut: String {
        didSet { defaults.set(globalShortcut, forKey: "general.globalShortcut") }
    }

    @Published var restoreSession: Bool {
        didSet { defaults.set(restoreSession, forKey: "general.restoreSession") }
    }

    // MARK: Sidebar

    @Published var edge: SidebarEdge {
        didSet { defaults.set(edge.rawValue, forKey: "sidebar.edge") }
    }

    @Published var sidebarWidth: Double {
        didSet { defaults.set(sidebarWidth, forKey: "sidebar.width") }
    }

    /// Seconds the pointer must rest on the edge before revealing.
    @Published var revealDelay: Double {
        didSet { defaults.set(revealDelay, forKey: "sidebar.revealDelay") }
    }

    /// Seconds after the pointer leaves before hiding.
    @Published var hideDelay: Double {
        didSet { defaults.set(hideDelay, forKey: "sidebar.hideDelay") }
    }

    @Published var animationSpeed: AnimationSpeed {
        didSet { defaults.set(animationSpeed.rawValue, forKey: "sidebar.animationSpeed") }
    }

    @Published var autoHide: Bool {
        didSet { defaults.set(autoHide, forKey: "sidebar.autoHide") }
    }

    @Published var alwaysOnTop: Bool {
        didSet { defaults.set(alwaysOnTop, forKey: "sidebar.alwaysOnTop") }
    }

    // MARK: Appearance

    @Published var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: "appearance.theme") }
    }

    /// Terminal background opacity, 0.5 ... 1.0.
    @Published var backgroundOpacity: Double {
        didSet { defaults.set(backgroundOpacity, forKey: "appearance.opacity") }
    }

    /// Background blur radius passed to Ghostty (0-40).
    @Published var blurAmount: Double {
        didSet { defaults.set(blurAmount, forKey: "appearance.blur") }
    }

    /// Empty string uses Ghostty's default font discovery.
    @Published var fontFamily: String {
        didSet { defaults.set(fontFamily, forKey: "appearance.fontFamily") }
    }

    @Published var fontSize: Double {
        didSet { defaults.set(fontSize, forKey: "appearance.fontSize") }
    }

    @Published var cursorStyle: TerminalCursorStyle {
        didSet { defaults.set(cursorStyle.rawValue, forKey: "appearance.cursorStyle") }
    }

    // MARK: Behavior

    @Published var keepOpenWhileTyping: Bool {
        didSet { defaults.set(keepOpenWhileTyping, forKey: "behavior.keepOpenWhileTyping") }
    }

    @Published var keepOpenWhileMouseInside: Bool {
        didSet { defaults.set(keepOpenWhileMouseInside, forKey: "behavior.keepOpenWhileMouseInside") }
    }

    /// Requires the pointer to genuinely enter the sidebar before auto-hide arms,
    /// and adds hysteresis around the frame.
    @Published var preventAccidentalHiding: Bool {
        didSet { defaults.set(preventAccidentalHiding, forKey: "behavior.preventAccidentalHiding") }
    }

    @Published var restoreWorkspace: Bool {
        didSet { defaults.set(restoreWorkspace, forKey: "behavior.restoreWorkspace") }
    }

    /// Empty uses the user's home directory.
    @Published var workingDirectory: String {
        didSet { defaults.set(workingDirectory, forKey: "behavior.workingDirectory") }
    }

    // MARK: Advanced

    /// Command executed when a new session starts. Empty runs the shell.
    @Published var startupCommand: String {
        didSet { defaults.set(startupCommand, forKey: "advanced.startupCommand") }
    }

    /// Empty uses the user's login shell.
    @Published var shellPath: String {
        didSet { defaults.set(shellPath, forKey: "advanced.shellPath") }
    }

    // MARK: Init

    private init() {
        let d = defaults
        launchAtLogin = d.object(forKey: "general.launchAtLogin") as? Bool ?? false
        showMenuBarIcon = d.object(forKey: "general.showMenuBarIcon") as? Bool ?? true
        showInDock = d.object(forKey: "general.showInDock") as? Bool ?? true
        globalShortcut = d.string(forKey: "general.globalShortcut") ?? "cmd+shift+grave"
        restoreSession = d.object(forKey: "general.restoreSession") as? Bool ?? true

        edge = SidebarEdge(rawValue: d.string(forKey: "sidebar.edge") ?? "") ?? .right
        sidebarWidth = d.object(forKey: "sidebar.width") as? Double ?? 520
        revealDelay = d.object(forKey: "sidebar.revealDelay") as? Double ?? 0.12
        hideDelay = d.object(forKey: "sidebar.hideDelay") as? Double ?? 0.5
        animationSpeed = AnimationSpeed(rawValue: d.string(forKey: "sidebar.animationSpeed") ?? "") ?? .balanced
        autoHide = d.object(forKey: "sidebar.autoHide") as? Bool ?? true
        alwaysOnTop = d.object(forKey: "sidebar.alwaysOnTop") as? Bool ?? true

        theme = AppTheme(rawValue: d.string(forKey: "appearance.theme") ?? "") ?? .system
        backgroundOpacity = d.object(forKey: "appearance.opacity") as? Double ?? 0.82
        blurAmount = d.object(forKey: "appearance.blur") as? Double ?? 24
        fontFamily = d.string(forKey: "appearance.fontFamily") ?? ""
        fontSize = d.object(forKey: "appearance.fontSize") as? Double ?? 13
        cursorStyle = TerminalCursorStyle(rawValue: d.string(forKey: "appearance.cursorStyle") ?? "") ?? .block

        keepOpenWhileTyping = d.object(forKey: "behavior.keepOpenWhileTyping") as? Bool ?? true
        keepOpenWhileMouseInside = d.object(forKey: "behavior.keepOpenWhileMouseInside") as? Bool ?? true
        preventAccidentalHiding = d.object(forKey: "behavior.preventAccidentalHiding") as? Bool ?? true
        restoreWorkspace = d.object(forKey: "behavior.restoreWorkspace") as? Bool ?? true
        workingDirectory = d.string(forKey: "behavior.workingDirectory") ?? ""

        startupCommand = d.string(forKey: "advanced.startupCommand") ?? ""
        shellPath = d.string(forKey: "advanced.shellPath") ?? ""
    }

    private func applyLaunchAtLogin() {
        guard Bundle.main.bundleIdentifier != nil else { return }
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Launch at login update failed: \(error)")
        }
    }

    /// Re-assert login-item registration at startup: the app may have moved
    /// on disk, or the user may have removed it in System Settings.
    func reconcileLaunchAtLogin() {
        guard launchAtLogin else { return }
        applyLaunchAtLogin()
    }

    /// Restore every setting to its factory value. Each assignment runs the
    /// normal didSet persistence, and the publishers fan the changes out to
    /// the live app exactly like edits made by hand.
    func resetToDefaults() {
        launchAtLogin = false
        showMenuBarIcon = true
        showInDock = true
        globalShortcut = "cmd+shift+grave"
        restoreSession = true

        edge = .right
        sidebarWidth = 520
        revealDelay = 0.12
        hideDelay = 0.5
        animationSpeed = .balanced
        autoHide = true
        alwaysOnTop = true

        theme = .system
        backgroundOpacity = 0.82
        blurAmount = 24
        fontFamily = ""
        fontSize = 13
        cursorStyle = .block

        keepOpenWhileTyping = true
        keepOpenWhileMouseInside = true
        preventAccidentalHiding = true
        restoreWorkspace = true
        workingDirectory = ""

        startupCommand = ""
        shellPath = ""
    }

    // MARK: Ghostty config generation

    /// Directory holding SideTerminal's generated Ghostty configuration.
    static var configDirectory: URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        return base.appendingPathComponent("SideTerminal", isDirectory: true)
    }

    static var configFile: URL {
        configDirectory.appendingPathComponent("terminal-config")
    }

    /// Render the terminal engine's configuration from current settings.
    /// The rendering logic lives in SideTerminalCore so it is unit-tested.
    func terminalConfig() -> String {
        let mode: TerminalThemeMode
        switch theme {
        case .system: mode = .system
        case .light: mode = .light
        case .dark: mode = .dark
        }
        return renderTerminalConfig(TerminalConfigInput(
            backgroundOpacity: backgroundOpacity,
            blurAmount: blurAmount,
            cursorStyle: cursorStyle.rawValue,
            fontSize: fontSize,
            fontFamily: fontFamily,
            theme: mode,
            workingDirectory: workingDirectory,
            homeDirectory: NSHomeDirectory(),
            shellPath: shellPath
        ))
    }

    /// Write the generated config to disk, returning its path.
    @discardableResult
    func writeTerminalConfig() -> String {
        let dir = Self.configDirectory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = Self.configFile
        try? terminalConfig().write(to: url, atomically: true, encoding: .utf8)
        return url.path
    }
}
