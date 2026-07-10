import AppKit
import SwiftUI

/// Native preferences window: toolbar tabs + grouped SwiftUI forms.
@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings

        let tabs = NSTabViewController()
        tabs.tabStyle = .toolbar

        func pane<Content: View>(
            _ title: String,
            symbol: String,
            _ content: Content
        ) -> NSTabViewItem {
            let host = NSHostingController(
                rootView: content
                    .environmentObject(settings)
                    .frame(width: 560)
            )
            // Let the hosting controller drive the window size so each tab
            // fits its content and tab switches animate the resize natively.
            host.sizingOptions = [.preferredContentSize]
            // NSTabViewController adopts the selected controller's title as
            // the window title; the app is called SideTerminal, everywhere.
            host.title = "SideTerminal"
            let item = NSTabViewItem(viewController: host)
            item.label = title
            item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
            return item
        }

        tabs.addTabViewItem(pane("General", symbol: "gearshape", GeneralPane()))
        tabs.addTabViewItem(pane("Sidebar", symbol: "sidebar.right", SidebarPane()))
        tabs.addTabViewItem(pane("Appearance", symbol: "paintbrush", AppearancePane()))
        tabs.addTabViewItem(pane("Behavior", symbol: "cursorarrow.motionlines", BehaviorPane()))
        tabs.addTabViewItem(pane("Advanced", symbol: "wrench.and.screwdriver", AdvancedPane()))
        tabs.addTabViewItem(pane("About", symbol: "info.circle", AboutPane()))

        let window = NSWindow(contentViewController: tabs)
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.titlebarSeparatorStyle = .automatic
        window.toolbarStyle = .preference
        window.title = "SideTerminal"
        window.isReleasedWhenClosed = false

        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func show() {
        guard let window else { return }
        // Settings is a real window; activate so it comes forward. As an
        // accessory app we must be explicit about ordering.
        NSApp.activate(ignoringOtherApps: true)
        if window.frameAutosaveName.isEmpty {
            window.setFrameAutosaveName("com.sideterminal.settings")
        }
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }
}
