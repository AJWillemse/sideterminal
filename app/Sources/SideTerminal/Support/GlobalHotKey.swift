import AppKit
import Carbon.HIToolbox
import SideTerminalCore

// HotKeySpec (shortcut parsing) lives in SideTerminalCore so it's unit-tested.

/// System-wide hotkey via Carbon's RegisterEventHotKey — no accessibility
/// permission required, works even while other apps are focused.
final class GlobalHotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let callback: () -> Void

    /// Trial-register the combo to learn whether the system will grant it
    /// (another app may already own it), then release it immediately.
    static func isAvailable(_ spec: HotKeySpec) -> Bool {
        let hotKeyID = EventHotKeyID(signature: OSType(0x53544d4c), id: 0xFFFF)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            spec.keyCode,
            spec.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        guard status == noErr, let ref else { return false }
        UnregisterEventHotKey(ref)
        return true
    }

    private static var installedHandlers: [UInt32: GlobalHotKey] = [:]
    private static var nextID: UInt32 = 1

    private let id: UInt32

    init?(spec: HotKeySpec, callback: @escaping () -> Void) {
        self.callback = callback
        self.id = Self.nextID
        Self.nextID += 1

        let hotKeyID = EventHotKeyID(signature: OSType(0x53544d4c) /* 'STML' */, id: id)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            spec.keyCode,
            spec.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        guard status == noErr, let ref else { return nil }
        hotKeyRef = ref
        Self.installedHandlers[id] = self

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                var hkID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkID
                )
                if let handler = GlobalHotKey.installedHandlers[hkID.id] {
                    DispatchQueue.main.async { handler.callback() }
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )
    }

    deinit {
        Self.installedHandlers[id] = nil
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }
}
