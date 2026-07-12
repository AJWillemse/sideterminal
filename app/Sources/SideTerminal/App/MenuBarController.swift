import AppKit

/// The app's quiet home in the menu bar. Minimal by design.
@MainActor
final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private weak var appDelegate: AppDelegate?

    /// Single show/hide entry whose title tracks the sidebar's state.
    private var toggleItem: NSMenuItem?

    /// "Terminal Sessions" entry; its submenu is rebuilt on every open.
    private var sessionsItem: NSMenuItem?

    private static let sessionTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    init(delegate: AppDelegate) {
        self.appDelegate = delegate
        super.init()
        updateVisibility()
    }

    func updateVisibility() {
        let wanted = AppSettings.shared.showMenuBarIcon
        if wanted, statusItem == nil {
            install()
        } else if !wanted, let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        } else {
            updateIcon()
        }
    }

    private func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item
        updateIcon()

        let menu = NSMenu()
        menu.delegate = self

        // One entry, not Show + Hide: the title flips with the sidebar's
        // real state every time the menu opens.
        let toggle = NSMenuItem(title: "Show Sidebar", action: #selector(AppDelegate.toggleSidebar), keyEquivalent: "")
        toggleItem = toggle
        // Routed through a local trampoline: macOS 26 infers a gear icon for
        // items whose action is the well-known openSettings selector, which
        // breaks the menu's alignment.
        let settings = NSMenuItem(title: "Settings…", action: #selector(menuOpenSettings), keyEquivalent: "")
        let checkForUpdates = NSMenuItem(title: "Check for Updates…", action: #selector(menuCheckForUpdates), keyEquivalent: "")
        let restart = NSMenuItem(title: "Restart Terminal Session", action: #selector(AppDelegate.restartSession), keyEquivalent: "")
        let quit = NSMenuItem(title: "Quit SideTerminal", action: #selector(AppDelegate.quit), keyEquivalent: "q")

        for entry in [toggle, settings, checkForUpdates, restart, quit] {
            entry.target = appDelegate
            // Keep the menu clean and perfectly aligned: no per-item icons.
            entry.image = nil
        }
        settings.target = self
        checkForUpdates.target = self

        // Hovering opens the last-10 session switcher to the side.
        let sessions = NSMenuItem(title: "Terminal Sessions", action: nil, keyEquivalent: "")
        sessions.submenu = NSMenu(title: "Terminal Sessions")
        sessions.image = nil
        sessionsItem = sessions

        menu.addItem(toggle)
        menu.addItem(.separator())
        menu.addItem(sessions)
        menu.addItem(.separator())
        menu.addItem(settings)
        menu.addItem(checkForUpdates)
        menu.addItem(restart)
        menu.addItem(.separator())
        menu.addItem(quit)

        item.menu = menu
    }

    private func rebuildSessionsSubmenu() {
        guard let submenu = sessionsItem?.submenu,
              let sidebar = appDelegate?.sidebar else { return }
        submenu.removeAllItems()

        let newSession = NSMenuItem(
            title: "New Session",
            action: #selector(menuNewSession),
            keyEquivalent: ""
        )
        newSession.target = self
        submenu.addItem(newSession)

        let infos = sidebar.sessionInfos()
        guard !infos.isEmpty else { return }
        submenu.addItem(.separator())

        for info in infos {
            let time = Self.sessionTimeFormatter.string(from: info.createdAt)
            let entry = NSMenuItem(
                title: "\(info.title)  —  \(time)",
                action: #selector(menuSelectSession(_:)),
                keyEquivalent: ""
            )
            entry.target = self
            entry.representedObject = info.id
            entry.state = info.isActive ? .on : .off
            entry.image = nil
            submenu.addItem(entry)
        }
    }

    @objc private func menuNewSession() {
        appDelegate?.sidebar.newSession()
        appDelegate?.showSidebar()
    }

    @objc private func menuSelectSession(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID else { return }
        appDelegate?.sidebar.switchToSession(id: id)
        appDelegate?.showSidebar()
    }

    @objc private func menuOpenSettings() {
        appDelegate?.openSettings()
    }

    @objc private func menuCheckForUpdates() {
        appDelegate?.checkForUpdates(nil)
    }

    private func updateIcon() {
        guard let button = statusItem?.button else { return }
        // The app's own mark, as a pure monochrome template so it renders
        // like every native status item in light, dark, and tinted bars.
        if let url = Bundle.main.url(forResource: "MenuBarIcon", withExtension: "png"),
           let icon = NSImage(contentsOf: url) {
            if let retina = Bundle.main.url(forResource: "MenuBarIcon@2x", withExtension: "png"),
               let rep = NSImageRep(contentsOf: retina) {
                rep.size = icon.size
                icon.addRepresentation(rep)
            }
            icon.isTemplate = true
            button.image = icon
            return
        }
        let name = AppSettings.shared.edge == .left
            ? "sidebar.squares.left"
            : "sidebar.squares.right"
        let image = NSImage(systemSymbolName: name, accessibilityDescription: "SideTerminal")
            ?? NSImage(systemSymbolName: "terminal", accessibilityDescription: "SideTerminal")
        image?.isTemplate = true
        button.image = image
    }
}

extension MenuBarController: NSMenuDelegate {
    /// Runs as the menu opens: strip any icon the system injected so every
    /// row's text stays on the same left edge, and let the toggle entry
    /// reflect the sidebar's state right now.
    func menuNeedsUpdate(_ menu: NSMenu) {
        for item in menu.items { item.image = nil }
        if let state = appDelegate?.sidebar.state {
            let visible = state == .shown || state == .revealing
            toggleItem?.title = visible ? "Hide Sidebar" : "Show Sidebar"
        }
        rebuildSessionsSubmenu()
    }
}
