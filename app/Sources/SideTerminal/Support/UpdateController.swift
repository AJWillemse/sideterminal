import AppKit
import Sparkle

/// Owns the Sparkle auto-updater for SideTerminal.
///
/// Two deliberate design choices:
///
/// 1. Implements `SPUStandardUserDriverDelegate` with
///    `supportsGentleScheduledUpdateReminders = true`. This is Sparkle's
///    documented requirement for background/menu-bar apps — without it,
///    Sparkle shows a scary "Update Error!" modal whenever a background
///    check fails (e.g. no network, 404 on feed). With it, background
///    check errors are silently ignored; only user-triggered checks via
///    `checkForUpdates(_:)` ever show an error dialog.
///
/// 2. `SUAutomaticallyUpdate` is `false` in Info.plist so Sparkle never
///    installs an update without the user's explicit approval — correct
///    for an unsigned/unnotarized app where trust must be earned.
@MainActor
final class UpdateController: NSObject {
    static let shared = UpdateController()

    /// Lazy so `self` is fully initialised before we hand it to Sparkle
    /// as the user-driver delegate (Swift can't pass `self` before
    /// super.init() completes).
    private lazy var controller: SPUStandardUpdaterController =
        SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: self
        )

    var automaticallyChecksForUpdates: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set { controller.updater.automaticallyChecksForUpdates = newValue }
    }

    /// Called once at launch from AppDelegate. Accessing `controller`
    /// here triggers the lazy initialiser, starts Sparkle, and syncs the
    /// user's persisted auto-check preference.
    func applyInitialPreference(_ enabled: Bool) {
        controller.updater.automaticallyChecksForUpdates = enabled
    }

    /// Called by the menu bar "Check for Updates…" item, Ghostty's own
    /// GHOSTTY_ACTION_CHECK_FOR_UPDATES action, and the Settings button.
    /// This is user-initiated, so Sparkle shows its full native UI —
    /// including an error dialog if the feed is unreachable, which is
    /// appropriate (the user explicitly asked).
    func checkForUpdates(_ sender: Any?) {
        controller.checkForUpdates(sender)
    }
}

// MARK: - SPUStandardUserDriverDelegate

extension UpdateController: SPUStandardUserDriverDelegate {

    /// Opt into Sparkle's Gentle Reminders API.
    ///
    /// This single declaration is what stops the "Update Error!" modal
    /// from appearing on background/scheduled check failures. Per Sparkle
    /// docs: "Background (dockless) running apps may receive a log warning
    /// about scheduling update checks and not implementing gentle reminders.
    /// At minimum, this method needs to be implemented."
    ///
    /// With it: background check errors → silently ignored.
    /// Without it: background check errors → scary modal dialog (the bug).
    var supportsGentleScheduledUpdateReminders: Bool { true }

    /// Called when a scheduled background check finds a real update.
    /// Returning `true` tells Sparkle to handle showing the "Update
    /// Available" alert itself at an opportune moment. Return `false` here
    /// if you want to show your own badge/notification first instead.
    func standardUserDriverShouldHandleShowingScheduledUpdate(
        _ update: SUAppcastItem,
        andInImmediateFocus immediateFocus: Bool
    ) -> Bool {
        true
    }

    /// Suppress the "Version History" button in "You're up to date"
    /// alerts — the full changelog lives on GitHub, not in the app.
    func standardUserDriverShouldShowVersionHistory(
        for item: SUAppcastItem
    ) -> Bool {
        false
    }
}
