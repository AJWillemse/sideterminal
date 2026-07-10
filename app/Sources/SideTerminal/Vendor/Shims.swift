import AppKit

/// Minimal stand-in for Ghostty.app's window controller base class.
///
/// The vendored Ghostty layer routes a handful of window-scoped actions
/// (tabs, splits, palette) through `BaseTerminalController`. SideTerminal
/// intentionally has none of those chrome features — its single sidebar
/// panel is not managed by this controller — so these lookups simply fail
/// gracefully and the corresponding actions no-op.
/// Stand-in for Ghostty.app's terminal window classes. SideTerminal's panel
/// is not one of these, so casts fail and the related actions no-op.
class TerminalWindow: NSWindow {
    func isTabBar(_ childViewController: NSTitlebarAccessoryViewController) -> Bool { false }
}

class HiddenTitlebarTerminalWindow: TerminalWindow {}

/// Errors thrown by window state restoration (vendored signature).
enum TerminalRestoreError: Error {
    case delegateInvalid
    case identifierUnknown
    case stateDecodeFailed
    case windowDidNotLoad
}

class BaseTerminalController: NSWindowController {
    /// The surface tree for this window. Always empty here.
    var surfaceTree: SplitTree<Ghostty.SurfaceView> = .init()

    /// The focused surface for this window.
    var focusedSurface: Ghostty.SurfaceView? { nil }

    /// A user-set window title override.
    var titleOverride: String?

    /// Whether the command palette is showing.
    var commandPaletteIsShowing: Bool { false }

    /// Whether focus follows the mouse across splits.
    var focusFollowsMouse: Bool { false }

    func promptTabTitle() {}

    @objc func changeTabTitle(_ sender: Any?) {}

    func toggleBackgroundOpacity() {}
}
