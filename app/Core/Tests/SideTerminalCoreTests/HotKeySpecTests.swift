import XCTest
import AppKit
import Carbon.HIToolbox
@testable import SideTerminalCore

final class HotKeySpecTests: XCTestCase {
    func testParsesCommandShiftGrave() {
        let spec = HotKeySpec(string: "cmd+shift+grave")
        XCTAssertNotNil(spec)
        XCTAssertEqual(spec?.keyCode, UInt32(kVK_ANSI_Grave))
        XCTAssertEqual(spec?.carbonModifiers, UInt32(cmdKey) | UInt32(shiftKey))
        XCTAssertEqual(spec?.display, "⌘⇧`")
    }

    func testAcceptsModifierAliases() {
        XCTAssertNotNil(HotKeySpec(string: "command+option+t"))
        XCTAssertNotNil(HotKeySpec(string: "ctrl+alt+delete"))
        XCTAssertNotNil(HotKeySpec(string: "control+opt+k"))
    }

    func testDisplayUsesGlyphs() {
        // Glyphs follow the order the modifiers appear in the string; the
        // recorder always emits cmd, shift, alt, ctrl in that order.
        XCTAssertEqual(HotKeySpec(string: "cmd+shift+alt+ctrl+a")?.display, "⌘⇧⌥⌃A")
        XCTAssertEqual(HotKeySpec(string: "ctrl+space")?.display, "⌃Space")
        XCTAssertEqual(HotKeySpec(string: "cmd+escape")?.display, "⌘⎋")
    }

    func testRejectsMissingModifier() {
        XCTAssertNil(HotKeySpec(string: "grave"))
        XCTAssertNil(HotKeySpec(string: "a"))
    }

    func testRejectsUnknownKeyOrModifier() {
        XCTAssertNil(HotKeySpec(string: "cmd+florp"))
        XCTAssertNil(HotKeySpec(string: "hyper+a"))
        XCTAssertNil(HotKeySpec(string: ""))
    }

    func testReverseKeyMapRoundTrips() {
        for name in ["a", "t", "grave", "space", "f5", "left"] {
            let code = HotKeySpec.keyMap[name]!
            XCTAssertEqual(HotKeySpec.reverseKeyMap[code], name)
        }
    }

    func testFromEventBuildsCanonicalString() {
        let event = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [.command, .shift],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "`",
            charactersIgnoringModifiers: "`",
            isARepeat: false,
            keyCode: UInt16(kVK_ANSI_Grave)
        )!
        let result = HotKeySpec.from(event: event)
        XCTAssertEqual(result?.string, "cmd+shift+grave")
        XCTAssertEqual(result?.spec.display, "⌘⇧`")
    }

    func testFromEventRejectsShiftOnly() {
        let event = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [.shift],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "A",
            charactersIgnoringModifiers: "a",
            isARepeat: false,
            keyCode: UInt16(kVK_ANSI_A)
        )!
        XCTAssertNil(HotKeySpec.from(event: event))
    }
}
