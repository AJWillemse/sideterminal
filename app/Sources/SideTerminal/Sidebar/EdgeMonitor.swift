import AppKit

/// Watches the pointer for contact with the configured screen edge.
///
/// Uses lightweight polling of `NSEvent.mouseLocation` (no event tap, no
/// accessibility permission). The poll rate adapts: slow when the pointer is
/// far from the edge, fast when close, so idle CPU stays negligible.
@MainActor
final class EdgeMonitor {
    /// Called once the pointer has rested on the edge for `revealDelay`.
    /// Argument is the screen whose edge was touched.
    var onEdgeDwell: ((NSScreen) -> Void)?

    var edge: SidebarEdge = .right
    var revealDelay: TimeInterval = 0.12
    var isEnabled = true

    /// Width of the invisible hot strip at the screen edge.
    private let hotZone: CGFloat = 3
    /// Distance considered "near" for adaptive polling.
    private let nearZone: CGFloat = 96

    private var timer: Timer?
    private var dwellStart: TimeInterval?
    private var firedForCurrentDwell = false

    func start() {
        schedule(interval: 1.0 / 15.0)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func schedule(interval: TimeInterval) {
        if let timer, abs(timer.timeInterval - interval) < 0.001 { return }
        timer?.invalidate()
        let t = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        // Common modes so detection keeps working while menus/drags run loops.
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        guard isEnabled else {
            dwellStart = nil
            firedForCurrentDwell = false
            schedule(interval: 1.0 / 15.0)
            return
        }

        let location = NSEvent.mouseLocation
        guard let screen = screenContaining(location) else { return }

        let frame = screen.frame
        let distance: CGFloat
        switch edge {
        case .left: distance = location.x - frame.minX
        case .right: distance = frame.maxX - location.x
        }

        // Adaptive poll rate.
        schedule(interval: distance <= nearZone ? 1.0 / 60.0 : 1.0 / 15.0)

        let now = ProcessInfo.processInfo.systemUptime
        if distance <= hotZone {
            if dwellStart == nil { dwellStart = now }
            if !firedForCurrentDwell, now - (dwellStart ?? now) >= revealDelay {
                firedForCurrentDwell = true
                onEdgeDwell?(screen)
            }
        } else {
            dwellStart = nil
            firedForCurrentDwell = false
        }
    }

    private func screenContaining(_ point: NSPoint) -> NSScreen? {
        NSScreen.screens.first { NSMouseInRect(point, $0.frame, false) }
    }
}
