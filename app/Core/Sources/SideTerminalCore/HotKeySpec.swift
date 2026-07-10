import AppKit
import Carbon.HIToolbox

/// A parsed global hotkey like "cmd+shift+grave" or "cmd+alt+t".
///
/// Encapsulates the mapping between human-readable shortcut strings, macOS
/// virtual key codes + Carbon modifier masks, and a display string using the
/// familiar ⌘⇧⌥⌃ glyphs.
public struct HotKeySpec: Equatable {
    public let keyCode: UInt32
    public let carbonModifiers: UInt32
    public let display: String

    /// Supported key names mapped to virtual key codes.
    public static let keyMap: [String: Int] = [
        "a": kVK_ANSI_A, "b": kVK_ANSI_B, "c": kVK_ANSI_C, "d": kVK_ANSI_D,
        "e": kVK_ANSI_E, "f": kVK_ANSI_F, "g": kVK_ANSI_G, "h": kVK_ANSI_H,
        "i": kVK_ANSI_I, "j": kVK_ANSI_J, "k": kVK_ANSI_K, "l": kVK_ANSI_L,
        "m": kVK_ANSI_M, "n": kVK_ANSI_N, "o": kVK_ANSI_O, "p": kVK_ANSI_P,
        "q": kVK_ANSI_Q, "r": kVK_ANSI_R, "s": kVK_ANSI_S, "t": kVK_ANSI_T,
        "u": kVK_ANSI_U, "v": kVK_ANSI_V, "w": kVK_ANSI_W, "x": kVK_ANSI_X,
        "y": kVK_ANSI_Y, "z": kVK_ANSI_Z,
        "0": kVK_ANSI_0, "1": kVK_ANSI_1, "2": kVK_ANSI_2, "3": kVK_ANSI_3,
        "4": kVK_ANSI_4, "5": kVK_ANSI_5, "6": kVK_ANSI_6, "7": kVK_ANSI_7,
        "8": kVK_ANSI_8, "9": kVK_ANSI_9,
        "grave": kVK_ANSI_Grave, "`": kVK_ANSI_Grave,
        "space": kVK_Space,
        "escape": kVK_Escape,
        "f1": kVK_F1, "f2": kVK_F2, "f3": kVK_F3, "f4": kVK_F4,
        "f5": kVK_F5, "f6": kVK_F6, "f7": kVK_F7, "f8": kVK_F8,
        "f9": kVK_F9, "f10": kVK_F10, "f11": kVK_F11, "f12": kVK_F12,
        "minus": kVK_ANSI_Minus, "equal": kVK_ANSI_Equal,
        "leftbracket": kVK_ANSI_LeftBracket, "rightbracket": kVK_ANSI_RightBracket,
        "semicolon": kVK_ANSI_Semicolon, "quote": kVK_ANSI_Quote,
        "comma": kVK_ANSI_Comma, "period": kVK_ANSI_Period,
        "slash": kVK_ANSI_Slash, "backslash": kVK_ANSI_Backslash,
        "tab": kVK_Tab, "return": kVK_Return, "delete": kVK_Delete,
        "up": kVK_UpArrow, "down": kVK_DownArrow,
        "left": kVK_LeftArrow, "right": kVK_RightArrow,
        "home": kVK_Home, "end": kVK_End,
        "pageup": kVK_PageUp, "pagedown": kVK_PageDown,
    ]

    /// Key code → canonical name, for turning recorded events into specs.
    public static let reverseKeyMap: [Int: String] = {
        var map: [Int: String] = [:]
        for (name, code) in keyMap where name != "`" {
            map[code] = name
        }
        return map
    }()

    public init?(string: String) {
        let parts = string.lowercased()
            .split(separator: "+")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard let keyName = parts.last, parts.count >= 2 else { return nil }
        guard let code = Self.keyMap[keyName] else { return nil }

        var mods: UInt32 = 0
        var symbols = ""
        for part in parts.dropLast() {
            switch part {
            case "cmd", "command": mods |= UInt32(cmdKey); symbols += "⌘"
            case "shift": mods |= UInt32(shiftKey); symbols += "⇧"
            case "alt", "option", "opt": mods |= UInt32(optionKey); symbols += "⌥"
            case "ctrl", "control": mods |= UInt32(controlKey); symbols += "⌃"
            default: return nil
            }
        }
        guard mods != 0 else { return nil }

        keyCode = UInt32(code)
        carbonModifiers = mods

        let keyLabels: [String: String] = [
            "grave": "`", "space": "Space", "escape": "⎋",
            "tab": "⇥", "return": "↩", "delete": "⌫",
            "up": "↑", "down": "↓", "left": "←", "right": "→",
            "home": "↖", "end": "↘", "pageup": "⇞", "pagedown": "⇟",
            "minus": "-", "equal": "=", "comma": ",", "period": ".",
            "slash": "/", "backslash": "\\", "semicolon": ";", "quote": "'",
            "leftbracket": "[", "rightbracket": "]",
        ]
        display = symbols + (keyLabels[keyName] ?? keyName.uppercased())
    }

    /// Build a spec (and its canonical settings string) from a key event
    /// captured by the shortcut recorder. Requires a real chord: at least
    /// one of ⌘ ⌥ ⌃ — shift alone can't be a global hotkey.
    public static func from(event: NSEvent) -> (spec: HotKeySpec, string: String)? {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags.contains(.command) || flags.contains(.option) || flags.contains(.control)
        else { return nil }
        guard let keyName = reverseKeyMap[Int(event.keyCode)] else { return nil }

        var parts: [String] = []
        if flags.contains(.command) { parts.append("cmd") }
        if flags.contains(.shift) { parts.append("shift") }
        if flags.contains(.option) { parts.append("alt") }
        if flags.contains(.control) { parts.append("ctrl") }
        parts.append(keyName)

        let string = parts.joined(separator: "+")
        guard let spec = HotKeySpec(string: string) else { return nil }
        return (spec, string)
    }
}
